# Nix Binary Cache Proposal

## Goal

Set up a private Nix binary cache on the server to cache custom overlays and packages not available on cache.nixos.org. All devices should pull from this cache as a fallback.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Server (24/7) - x86_64-linux                           │
│  ┌─────────────────┐    ┌─────────────────────────────┐ │
│  │ systemd timer   │───▶│ Build flake outputs         │ │
│  │ (scheduled)     │    │ → results land in /nix/store│ │
│  └─────────────────┘    └─────────────────────────────┘ │
│           │                                             │
│           ▼                                             │
│  ┌─────────────────┐                                    │
│  │ Harmonia        │◀─── serves /nix/store over HTTP    │
│  │ :5000           │                                    │
│  └─────────────────┘                                    │
└─────────────────────────────────────────────────────────┘
              │
              │ Tailscale (server:5000)
              ▼
┌───────────────────────┐  ┌───────────────────────┐
│ Desktop               │  │ MacBook               │
│ substituters:         │  │ substituters:         │
│  1. cache.nixos.org   │  │  1. cache.nixos.org   │
│  2. http://server:5000│  │  2. http://server:5000│
└───────────────────────┘  └───────────────────────┘
```

## Substituter Priority

1. `cache.nixos.org` (default, highest priority)
2. `http://server:5000` (Harmonia on server via Tailscale)
3. Local build (fallback)

## Cache Software: Harmonia

**Why Harmonia over alternatives:**

| Feature        | Harmonia          | Attic                    | nix-serve       |
|----------------|-------------------|--------------------------|-----------------|
| Complexity     | Simple            | Complex (S3, database)   | Simple but dated|
| Performance    | Fast (Rust)       | Fast (Rust)              | Slower (Perl)   |
| GC             | System `nix-gc`   | Built-in LRU             | System `nix-gc` |
| Setup          | In nixpkgs        | Extra flake input        | In nixpkgs      |

Attic's features (multi-tenancy, S3, deduplication) are overkill for single-user home setup.

## Implementation Steps

### 1. Generate signing keypair (on server)

```bash
sudo nix-store --generate-binary-cache-key server-cache-1 /var/lib/secrets/harmonia.secret /var/lib/secrets/harmonia.pub
```

### 2. Server configuration

```nix
# system/hosts/server/default.nix (or appropriate module)
{ config, pkgs, ... }: {
  # Harmonia binary cache
  services.harmonia = {
    enable = true;
    signKeyPath = "/var/lib/secrets/harmonia.secret";
  };

  # Open port (Tailscale only, no need for public firewall)
  # Harmonia defaults to port 5000

  # Scheduled flake builds to populate cache
  systemd.timers.populate-cache = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";  # or "weekly"
      Persistent = true;
    };
  };

  systemd.services.populate-cache = {
    description = "Build flake outputs to populate binary cache";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    path = [ pkgs.nix pkgs.git ];
    script = ''
      cd /path/to/nix/flake
      nix flake update --commit-lock-file || true
      nix build .#nixosConfigurations.desktop.config.system.build.toplevel --no-link
      nix build .#nixosConfigurations.server.config.system.build.toplevel --no-link
      # Add other outputs as needed
    '';
  };

  # Garbage collection to manage disk space
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
```

### 3. Client configuration (desktop, macbook)

```nix
# In common nix settings or per-host
{ config, ... }: {
  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      "http://server:5000"  # Tailscale hostname
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "server-cache-1:CONTENTS_OF_HARMONIA_PUB_FILE"
    ];
  };
}
```

## Darwin/macOS Limitation

**Problem:** Cannot cross-compile Darwin packages from Linux. Apple's toolchain (Xcode, SDK, frameworks) is proprietary and only runs on macOS.

**Implications:** Server can only cache x86_64-linux packages. MacBook's custom overlays must be built on the MacBook itself.

### Solution: Post-Build Hook

Configure MacBook to automatically push locally-built packages to server cache:

```nix
# darwin configuration
{ config, ... }: {
  nix.settings.post-build-hook = "/etc/nix/upload-to-cache.sh";
}
```

```bash
#!/bin/sh
# /etc/nix/upload-to-cache.sh
set -eu
set -f  # disable globbing

if [ -n "$OUT_PATHS" ]; then
  exec nix copy --to "ssh://server" $OUT_PATHS
fi
```

**How it works:**
1. MacBook tries cache.nixos.org → found → done
2. MacBook tries server:5000 → found → done
3. MacBook builds locally → post-build hook uploads to server
4. Future builds pull from server (even after local GC)

**Trade-off:** First build of expensive overlay happens on MacBook. After that, it's cached on server forever.

### Alternative: GitHub Actions + Tailscale (Recommended)

Use GitHub Actions macOS runners to build Darwin packages, then push to server via Tailscale.

**Pricing:**
- macOS has 10x minute multiplier (2,000 free minutes = 200 macOS minutes)
- Weekly builds of ~10 min = ~40 min/month (fits in free tier)
- Public repos: unlimited free

**Setup steps:**

1. Create OAuth client in [Tailscale Admin Console](https://login.tailscale.com/admin/settings/oauth) with `auth_keys:write` scope

2. Add CI tag to Tailscale ACL policy:
```json
{
  "tagOwners": {
    "tag:ci": ["autogroup:admin"]
  },
  "acls": [
    {"action": "accept", "src": ["tag:ci"], "dst": ["server:*"]}
  ]
}
```

3. Add secrets to GitHub repo (Settings → Secrets):
   - `TS_OAUTH_CLIENT_ID`
   - `TS_OAUTH_SECRET`

4. Create workflow:

```yaml
# .github/workflows/build-darwin.yml
name: Build Darwin & Push to Cache
on:
  push:
    branches: [main]
    paths:
      - 'home/**'
      - 'system/**'
      - 'flake.nix'
      - 'flake.lock'
  schedule:
    - cron: '0 4 * * 0'  # weekly Sunday 4am UTC

jobs:
  build-darwin:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      # Connect to Tailnet (ephemeral node, auto-removes when done)
      - name: Connect to Tailscale
        uses: tailscale/github-action@v3
        with:
          oauth-client-id: ${{ secrets.TS_OAUTH_CLIENT_ID }}
          oauth-secret: ${{ secrets.TS_OAUTH_SECRET }}
          tags: tag:ci

      - uses: cachix/install-nix-action@v31

      - name: Build Darwin config
        run: nix build .#darwinConfigurations.macbook.system

      - name: Push to server cache
        run: nix copy --to ssh://server ./result
```

**How it works:**
1. GitHub runner joins Tailnet as ephemeral node tagged `tag:ci`
2. Builds Darwin flake output on real macOS hardware
3. Pushes result to server via Tailscale SSH
4. Runner auto-removes from Tailnet when done

**Benefits over post-build hook:**
- MacBook never builds expensive overlays locally
- Builds happen on fresh macOS environment
- Server cache is pre-populated before you need packages

### Other Cloud Options

- **nixbuild.net**: ~€0.12/CPU-hour, 25 free hours/month

## Open Questions

- [ ] Exact flake outputs to build in scheduled job
- [ ] Build frequency (daily vs weekly)
- [ ] Disk space allocation for cache on server
- [ ] Whether to implement post-build hook for MacBook immediately

## Resources

- [Harmonia GitHub](https://github.com/nix-community/harmonia)
- [Binary Cache - NixOS Wiki](https://nixos.wiki/wiki/Binary_Cache)
- [Post-build hook - Nix Manual](https://nix.dev/manual/nix/2.30/advanced-topics/post-build-hook)
- [devour-flake](https://github.com/srid/devour-flake) - build all flake outputs
- [Distributed builds - nix.dev](https://nix.dev/tutorials/nixos/distributed-builds-setup.html)
- [Tailscale GitHub Action](https://github.com/tailscale/github-action)
- [GitHub Actions Pricing](https://docs.github.com/en/billing/reference/actions-runner-pricing)

# Declarative Syncthing Proposal

## Goal

Set up fully declarative Syncthing configuration across all hosts. Device IDs, folders, and settings are managed in Nix—web UI changes are ignored on service restart.

## Problem

Syncthing generates a unique device ID from its certificate (`cert.pem`/`key.pem`) on first run. Without managing these declaratively:
- A fresh install gets a new device ID
- All other devices' folder configurations break
- Manual reconfiguration required on every reinstall

## Solution

Store each host's Syncthing cert/key in agenix. A shared module defines all devices and folders. Each host imports the module and references its own secrets.

## Implementation Steps

### 1. Extract existing certificates

On each device that already has Syncthing running:

```bash
# NixOS system service
sudo cat /var/lib/syncthing/.config/syncthing/cert.pem > ~/syncthing-cert.pem
sudo cat /var/lib/syncthing/.config/syncthing/key.pem > ~/syncthing-key.pem

# Home Manager service
cat ~/.config/syncthing/cert.pem > ~/syncthing-cert.pem
cat ~/.config/syncthing/key.pem > ~/syncthing-key.pem
```

Get the device ID (for reference):
```bash
syncthing --device-id
# or from web UI: Actions → Show ID
```

### 2. Add certificates to agenix

```nix
# secrets/secrets.nix
let
  desktop = "ssh-ed25519 AAAA...";
  server = "ssh-ed25519 AAAA...";
  macbook = "ssh-ed25519 AAAA...";
in {
  # Existing secrets...

  # Syncthing certs (each host only needs its own)
  "syncthing-desktop-cert.age".publicKeys = [ desktop ];
  "syncthing-desktop-key.age".publicKeys = [ desktop ];
  "syncthing-server-cert.age".publicKeys = [ server ];
  "syncthing-server-key.age".publicKeys = [ server ];
  "syncthing-macbook-cert.age".publicKeys = [ macbook ];
  "syncthing-macbook-key.age".publicKeys = [ macbook ];
}
```

Encrypt the certificates:
```bash
cd ~/nix/secrets
agenix -e syncthing-desktop-cert.age < ~/syncthing-cert.pem
agenix -e syncthing-desktop-key.age < ~/syncthing-key.pem
# repeat for each host
```

### 3. Create shared Syncthing module

```nix
# home/modules/syncthing.nix (or system/modules/ for NixOS service)
{ config, lib, ... }:

let
  # Device IDs - these never change once certs are locked in
  devices = {
    desktop = {
      id = "XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX";
    };
    server = {
      id = "YYYYYYY-YYYYYYY-YYYYYYY-YYYYYYY-YYYYYYY-YYYYYYY-YYYYYYY-YYYYYYY";
    };
    macbook = {
      id = "ZZZZZZZ-ZZZZZZZ-ZZZZZZZ-ZZZZZZZ-ZZZZZZZ-ZZZZZZZ-ZZZZZZZ-ZZZZZZZ";
    };
    phone = {
      id = "PPPPPPP-PPPPPPP-PPPPPPP-PPPPPPP-PPPPPPP-PPPPPPP-PPPPPPP-PPPPPPP";
    };
  };

  # All folder definitions in one place
  allFolders = {
    documents = {
      path = "~/Documents";
      devices = [ "desktop" "server" "macbook" ];
    };
    music = {
      path = "~/Music";
      devices = [ "desktop" "server" ];
    };
    photos = {
      path = "~/Photos";
      devices = [ "desktop" "server" "phone" ];
      versioning = {
        type = "staggered";
        params.maxAge = "30";  # days
      };
    };
    notes = {
      path = "~/Notes";
      devices = [ "desktop" "server" "macbook" "phone" ];
    };
  };

  # Helper to filter folders for current host
  foldersForHost = hostname:
    lib.filterAttrs (name: folder:
      lib.elem hostname folder.devices
    ) allFolders;

in {
  options.custom.syncthing = {
    enable = lib.mkEnableOption "declarative Syncthing";
    hostname = lib.mkOption {
      type = lib.types.str;
      description = "Current host's name in the devices list";
    };
  };

  config = lib.mkIf config.custom.syncthing.enable {
    services.syncthing = {
      enable = true;

      # Make Nix authoritative
      overrideDevices = true;
      overrideFolders = true;

      settings = {
        inherit devices;
        folders = foldersForHost config.custom.syncthing.hostname;

        options = {
          urAccepted = -1;  # Disable telemetry
          localAnnounceEnabled = true;
          relaysEnabled = true;
        };
      };
    };
  };
}
```

### 4. Per-host configuration

```nix
# home/hosts/desktop/default.nix
{ config, ... }: {
  imports = [ ../../modules/syncthing.nix ];

  age.secrets = {
    syncthing-cert.file = ../../../secrets/syncthing-desktop-cert.age;
    syncthing-key.file = ../../../secrets/syncthing-desktop-key.age;
  };

  custom.syncthing = {
    enable = true;
    hostname = "desktop";
  };

  services.syncthing = {
    cert = config.age.secrets.syncthing-cert.path;
    key = config.age.secrets.syncthing-key.path;
  };
}
```

### 5. Server as always-on sync hub

The server acts as the central node that's always available:

```nix
# system/hosts/server/syncthing.nix
{ config, ... }: {
  age.secrets = {
    syncthing-cert.file = ../../../secrets/syncthing-server-cert.age;
    syncthing-key.file = ../../../secrets/syncthing-server-key.age;
  };

  services.syncthing = {
    enable = true;
    user = "jeanluc";
    group = "users";
    dataDir = "/home/jeanluc";

    cert = config.age.secrets.syncthing-cert.path;
    key = config.age.secrets.syncthing-key.path;

    overrideDevices = true;
    overrideFolders = true;

    settings = {
      # Import from shared module or define inline
      devices = { /* ... */ };
      folders = { /* ... */ };
    };
  };

  # Open ports for LAN sync (optional if using Tailscale)
  services.syncthing.openDefaultPorts = true;
}
```

## Folder Configuration Options

### Folder types

```nix
folders.backup = {
  path = "~/Backup";
  devices = [ "desktop" "server" ];
  type = "sendonly";  # Desktop sends, doesn't receive deletions
};

folders.server-data = {
  path = "~/ServerData";
  devices = [ "desktop" "server" ];
  type = "receiveonly";  # Desktop only receives
};
```

### Versioning

```nix
folders.important = {
  path = "~/Important";
  devices = [ "desktop" "server" ];
  versioning = {
    type = "staggered";
    params = {
      cleanInterval = "3600";
      maxAge = "31536000";  # 1 year in seconds
    };
  };
};
```

### Ignore patterns

```nix
folders.code = {
  path = "~/Code";
  devices = [ "desktop" "macbook" ];
  ignorePatterns = [
    "node_modules"
    ".git"
    "target"
    "*.pyc"
    "__pycache__"
    ".direnv"
    "result"
  ];
};
```

## Phone Integration

Android Syncthing app can't be configured declaratively, but:
- Add phone's device ID to the `devices` attrset
- Include "phone" in relevant folders' device lists
- Phone will auto-accept shared folders if `autoAcceptFolders = true` is set

```nix
devices.phone = {
  id = "PPPPPPP-...";
  autoAcceptFolders = true;
};
```

## Comparison: Home Manager vs NixOS Service

| Aspect | Home Manager | NixOS System |
|--------|--------------|--------------|
| Runs as | User | Dedicated user (or specified) |
| Config location | `~/.config/syncthing` | `/var/lib/syncthing` |
| Permissions | User files only | Can sync system files |
| Starts | On user login | On boot |
| Best for | Desktop use | Server (24/7) |

For desktop, Home Manager service is usually preferred. For server, NixOS service ensures it starts on boot without login.

## Migration Path

1. Extract and encrypt existing certs for all hosts
2. Create shared module with current device IDs
3. Deploy to one host, verify web UI is read-only
4. Roll out to remaining hosts
5. Remove any manual folder configurations from web UI

## Open Questions

- [ ] Which folders to sync between which devices?
- [ ] Versioning policy for important folders?
- [ ] Use Home Manager service or NixOS service per host?
- [ ] Include phone in sync topology?

## Resources

- [Syncthing NixOS Wiki](https://nixos.wiki/wiki/Syncthing)
- [Home Manager Syncthing options](https://nix-community.github.io/home-manager/options.xhtml#opt-services.syncthing.enable)
- [Syncthing config reference](https://docs.syncthing.net/users/config.html)
- [Syncthing ignore patterns](https://docs.syncthing.net/users/ignoring.html)

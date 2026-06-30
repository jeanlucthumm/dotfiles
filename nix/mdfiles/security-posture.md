# Security Posture

Hardware-backed key management using YubiKeys on interactive workstations. Private keys never touch disk; cryptographic operations require physical hardware. Headless nodes (the server) can't use a hardware key — they're handled separately (see Keyless Nodes).

**Assumed baseline:** Full disk encryption (FileVault on macOS, LUKS on Linux) on all devices.

## Threat Model

**The model is wide-net, untargeted compromise — not a targeted attacker.** We optimize against generic malware (compromised npm/pypi/cargo/nix packages, drive-by credential stealers) that runs as our user and scans *standard* locations. We do **not** optimize against an adversary who has studied this specific setup. This distinction drives every decision below.

### Threats Addressed

| Threat | Likelihood | Mitigation |
|--------|------------|------------|
| **Supply chain — key theft** | Medium | Private keys live in the YubiKey, not on disk. Generic stealers scan `~/.ssh/id_*`, `~/.aws/credentials`, `.env` — and find nothing usable. A transient compromise can't walk away with reusable keys. |
| **Supply chain — secret theft** | Medium | *The hardware key does nothing here.* Decrypted API keys in active use are readable by any code running as us. Real mitigation is **isolation** — run untrusted dev work behind a sandbox boundary so it never shares the process space that holds the secrets (see Dev-Package Isolation). Fallbacks: rotation + non-standard paths. |
| **Phishing** | Medium-High | WebAuthn credentials are origin-bound — fake sites can't use them. Independent of supply chain. |
| **Device theft** | Low-Medium | Disk encryption + YubiKey PIN/touch required. |

### Out of Scope

- **Targeted attack** — An adversary who knows our custom secret paths, waits for a touch, or scrapes plaintext from a live process. By definition outside the wide-net model. Non-standard locations give marginal protection against scanners but zero against a targeted attacker.
- **Live secret confidentiality** — Once an API key is decrypted for use, code running as our user can read it. Unavoidable for any secret that actually gets used. Mitigation is rotation, not the hardware key.
- **Zero-day / RAT** — Sophisticated persistent compromise. Low likelihood, not worth optimizing for.
- **Irreplaceable secrets** — Physical-access attacks for rotatable secrets, and archival key storage. Handled separately if ever needed (see Backup Strategy).

### What the YubiKey Actually Buys You

Against the wide-net model, the hardware key's real value is narrow but genuine:

1. **No permanent key theft.** A transient compromise cannot exfiltrate the SSH/signing private key — it isn't on disk. After cleanup, the attacker holds no reusable credential. This is blast-radius / persistence reduction, not confidentiality.
2. **Phishing resistance.** Origin-bound WebAuthn. Real and supply-chain-independent.
3. **Device-theft protection.** PIN + touch gate at rest.

### What the YubiKey Does NOT Do

- It does **not** protect decrypted secrets during a live compromise. PIN+touch gates *when* decryption happens, not what happens to the plaintext afterward — the API key still lands in an env var / file / process, readable by malicious code running as us.
- Git signing is configured **no-touch** (frequent commits, low-value threat), so it can be abused silently while the key is plugged in. Accepted tradeoff.
- Therefore the actual defense for API-key confidentiality is **isolation** (below), not the hardware. The hardware keeps the *keys* safe, not the *secrets they unlock*.

## Dev-Package Isolation

The dominant wide-net supply-chain vector is **arbitrary code execution at install/build time** in language ecosystems: npm `postinstall`, pip `setup.py`, cargo `build.rs`, gems, plus editor extensions and `curl | bash` installers. The defining trait is "untrusted code runs as our user during a routine dev action" — at which point it can read decrypted secrets, `~/.ssh`, env, anything we can. The YubiKey is irrelevant to this; the only real defense is to deny that code our process space.

**Nix is already sandboxed; the gap is everything Nix doesn't cover.** `nix build` runs with no network and an isolated filesystem, so nixpkgs is comparatively low-risk. But the moment we `npm install` inside a `nix develop` / devenv shell, Nix protects us not at all — that process runs as us.

**devenv is reproducibility, not isolation.** A `devenv shell` pins packages but runs as our user with full access to keys and secrets. It does not constitute a sandbox. Isolation (the boundary) and reproducibility (the toolchain) are orthogonal — devenv can run *inside* a boundary, but never replaces one.

**The boundary:**

| Layer | Mechanism | Notes |
|-------|-----------|-------|
| Local (now) | Rootless container (Podman) / dev container | On macOS, containers already run inside a Linux VM (Colima/OrbStack/Docker Desktop) → VM-grade isolation for free. Container escape is a targeted-attacker concern, out of scope. |
| Future (endgame) | Ephemeral cloud agent sandboxes | Untrusted execution moves off the key-holding laptop entirely; the laptop becomes a thin client. Blast radius collapses to a disposable remote box. |

**Mount discipline is the whole game.** A boundary only holds if the sandbox *cannot* see host secrets. Bind-mounting `~/.ssh` or forwarding the SSH agent "for convenience" hands the boundary straight back. Sandboxes must not have our keys, decrypted agenix secrets, or broader home directory.

**Cloud agents move the secret problem, they don't erase it.** A cloud sandbox still needs scoped credentials (git push, deploy, API keys) to do real work, and those are readable inside the sandbox — the same live-secret exposure that's out of scope above. The win is laptop isolation, which is real and worth it. The required hygiene is **per-sandbox, narrowly-scoped, short-lived credentials** — not the broad personal keys.

## YubiKey Inventory

| Key | Location | Purpose |
|-----|----------|---------|
| Desktop YubiKey | Desktop workstation | Full setup |
| MacBook YubiKey | MacBook | Full setup |
| Wallet NFC | Wallet | Phone 2FA + 2FA backup |

No agenix backup key. Agenix secrets are recoverable from provider dashboards (which require 2FA — see Backup Strategy).

## Per-Device YubiKey Configuration

Each workstation YubiKey (desktop, macbook) has identical configuration across two applets.

### FIDO2 Applet

| Credential | Type | Policy | Rationale |
|------------|------|--------|-----------|
| SSH auth | `ed25519-sk` resident | Touch required | Protect server access |
| Git signing | `ed25519-sk` resident | No touch | Frequent commits, low-value threat |
| Web 2FA | WebAuthn | Site-controlled | Not our choice |

Two separate FIDO2 credentials because SSH auth and git signing have different friction tolerances.

### PIV Applet

| Slot | Purpose | Policy | Rationale |
|------|---------|--------|-----------|
| 82 (retired key management) | Age identity (agenix) | PIN + touch | High-value API keys, low frequency (~1x/day) |

`age-plugin-yubikey` uses PIV retired key management slots (82-95), not standard PIV slots like 9a.

PIN and PUK changed from defaults on setup. Three wrong PIN attempts locks the slot (PUK to reset). Three wrong PUK attempts bricks the slot.

## Wallet NFC Key

Dual purpose:
- **Phone 2FA** — WebAuthn credentials for mobile authentication
- **2FA backup** — Survives an overnight disaster that takes both workstation keys

NOT an agenix recipient. If lost, deregister from web accounts (still have workstation keys).

## Keyless Nodes (Server)

**The structural problem:** a YubiKey requires interactive physical presence — PIN entry and touch. The server is headless and boots unattended (remote reboots). There is no human and no key at boot time. So the server **cannot** be a YubiKey-backed agenix recipient: nothing can perform the PIN+touch decryption.

**The two options for a keyless node both end with plaintext-equivalent on disk:**

| Approach | Where the decryption authority lives | Server in recipient set? |
|----------|--------------------------------------|--------------------------|
| Standard agenix on server | Server's SSH host key — an unattended key sitting on the server's disk | Yes (must rekey on changes) |
| **Push-over-SSH (chosen pattern)** | MacBook YubiKey only — never on the server | No |

Both expose secrets to anything running on the server (a host-key on disk decrypts everything; deposited plaintext is readable). At-rest cold-theft is covered by LUKS either way. The push-over-SSH approach is preferred because:

- The **master decryption authority (YubiKey) never lives on the always-on, most-exposed box.** Re-provisioning requires the operator + key to be physically present.
- The server stays **out of the agenix recipient set entirely** — no host-key recipient to manage or rekey.
- Secrets are deposited at a **non-standard location**, which (per the wide-net threat model) dodges generic credential scanners. Marginal, honest, consistent with the rest of the model.

**Mechanism:** a script run from the macbook decrypts the needed secrets locally (YubiKey PIN+touch), then deposits the plaintext over SSH into a chosen location on the server for the consuming service to read.

> **Current status:** No server-side secret consumer exists today (moltbot, the previous consumer, is retired). The deposit script and target path are therefore not yet wired into this repo. The standard-agenix remnants for moltbot (`keys.server` in `withServer`, the `moltbot-*.age` secrets, and `moltbot/default.nix`'s `age.secrets`) are **dead code pending cleanup**. The `# TODO: figure out the secrets story for server` in `hosts/server.nix` resolves to: use push-over-SSH when a consumer reappears; the server is not an agenix recipient.

## Agenix Configuration

**Recipients:** workstation age public keys only (desktop + macbook YubiKey PIV). The server is **not** a recipient — keyless nodes receive plaintext via push-over-SSH, not `.age` files.

```nix
# secrets/_pubkeys.nix (age identities)
{
  desktop.age = "age1yubikey1q...";  # Desktop YubiKey PIV
  macbook.age = "age1yubikey1q...";  # MacBook YubiKey PIV
}
```

**Identity:** Each device uses its own YubiKey PIV identity for decryption.

**Secret classification:** Only recoverable secrets (API keys, service credentials). See Backup Strategy for irreplaceable secrets.

## Backup Strategy

**N+1 terminology:** If N devices need to decrypt secrets, an N+1 setup adds one extra backup key stored offline, used only if all N primary keys are lost.

### 2FA Backup

Critical: without 2FA, can't access dashboards to rotate API keys.

**Strategy:** Register all three YubiKeys (desktop, macbook, wallet) with critical services. Wallet key is geographically separate, survives a home disaster.

**Additionally:** Save backup codes offered by services.

### Agenix: No Backup Key

Agenix secrets are operational (daily system ops), not archival:
- API keys can be rotated from provider dashboards
- Database passwords can be reset
- Service credentials can be regenerated

If all YubiKeys are lost (catastrophic overnight disaster), recovery is:
1. Get new YubiKeys
2. Log into each service dashboard
3. Rotate/regenerate credentials
4. Rebuild nix config

Annoying, not catastrophic. N+1 backup not justified for recoverable secrets.

### Agenix: Future Irreplaceable Secrets

If ever storing secrets that cannot be regenerated (crypto keys, archival encryption), add N+1 backup:
- Additional YubiKey stored offsite (bank safe deposit box)
- Added as agenix recipient alongside primary keys
- Those `.age` files stored privately, not in public dotfiles

The tooling supports this; it's an operational choice, not a technical limitation.

## Protocol Reference

| Operation | Protocol | Applet | Can Exfiltrate Key? |
|-----------|----------|--------|---------------------|
| SSH auth | FIDO2 | FIDO2 | No |
| Git signing | FIDO2 | FIDO2 | No |
| Web 2FA | WebAuthn/FIDO2 | FIDO2 | No |
| Age encrypt | - | - | Uses public key only |
| Age decrypt | PIV | PIV | No |

FIDO2 supports auth/signing but not encryption (protocol limitation). PIV supports encryption. Hence two applets.

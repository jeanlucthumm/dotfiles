# Security Posture

Hardware-backed key management using YubiKeys. Private keys never touch disk; all cryptographic operations require physical hardware.

**Assumed baseline:** Full disk encryption (FileVault on macOS, LUKS on Linux) on all devices.

## Threat Model

### Threats Addressed

| Threat | Likelihood | Mitigation |
|--------|------------|------------|
| **Supply chain exfiltration** | Medium | Keys not on disk - malicious packages can't steal them |
| **Phishing** | Medium-High | WebAuthn credentials are origin-bound - fake sites can't use them |
| **Device theft** | Low-Medium | Disk encryption + YubiKey PIN/touch required |

### Out of Scope

- **Zero-day / RAT** - Sophisticated persistent compromise. Low likelihood, not worth optimizing for.
- **Evil maid for API keys** - Physical access attacks for rotatable secrets. Cost/benefit doesn't justify.
- **Irreplaceable secrets** - Handled separately if ever needed (see Backup Strategy section).

## YubiKey Inventory

| Key | Location | Purpose |
|-----|----------|---------|
| Desktop YubiKey | Desktop workstation | Full setup |
| MacBook YubiKey | MacBook | Full setup |
| Wallet NFC | Wallet | Phone 2FA + 2FA backup |

No agenix backup key. Agenix secrets are recoverable from provider dashboards (which require 2FA - see backup strategy).

## Per-Device YubiKey Configuration

Each workstation YubiKey (desktop, macbook) has identical configuration across two applets:

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
- **Phone 2FA** - WebAuthn credentials for mobile authentication
- **2FA backup** - Survives overnight disaster that takes both workstation keys

NOT an agenix recipient. If lost, deregister from web accounts (still have workstation keys).

## Agenix Configuration

**Recipients:** All workstation age public keys (desktop + macbook)

```nix
# secrets/pubkeys.nix
{
  desktop = "age1yubikey1q...";  # Desktop YubiKey PIV
  macbook = "age1yubikey1q...";  # MacBook YubiKey PIV
}
```

**Identity:** Each device uses its own YubiKey PIV identity for decryption.

**Secret classification:** Only recoverable secrets (API keys, service credentials). See backup strategy section for irreplaceable secrets.

## Backup Strategy

**N+1 terminology:** If you have N devices that need to decrypt secrets, an N+1 setup adds one extra backup key stored offline. This backup is only used if all N primary keys are lost.

### 2FA Backup

Critical: Without 2FA, can't access dashboards to rotate API keys.

**Strategy:** Register all three YubiKeys (desktop, macbook, wallet) with critical services. Wallet key is geographically separate, survives home disaster.

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

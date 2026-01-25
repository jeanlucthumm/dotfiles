# Security Posture

Hardware-backed key management using YubiKeys. Replaces software keys in `~/.ssh/` to protect against supply chain exfiltration attacks.

## Threat Model

**Primary concern:** Malicious packages (npm, pip, etc.) exfiltrating private keys from disk.

**Solution:** Private keys never touch disk. All cryptographic operations require physical hardware.

**Out of scope:**
- Evil maid attacks for API keys (cost/benefit doesn't justify)
- Irreplaceable secrets (handled separately if needed, not in agenix)

## YubiKey Inventory

| Key | Location | Purpose |
|-----|----------|---------|
| Desktop YubiKey | Desktop workstation | Full setup |
| MacBook YubiKey | MacBook | Full setup |
| Wallet NFC | Wallet | Phone web 2FA only |

No N+1 backup key. Agenix secrets are API keys, recoverable from provider dashboards.

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
| 9a | Age identity (agenix) | PIN + touch | High-value API keys, low frequency (~1x/day) |

PIN and PUK changed from defaults on setup. Three wrong PIN attempts locks the slot (PUK to reset). Three wrong PUK attempts bricks the slot.

## Wallet NFC Key

Dedicated to phone web 2FA only:
- WebAuthn credentials for mobile authentication
- NOT an agenix recipient
- Easily revocable if lost (just deregister from web accounts)

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

**Secret classification:** Only recoverable secrets (API keys, service credentials). Irreplaceable secrets would use a separate system with N+1 redundancy.

## Why No Backup Key

Agenix secrets are operational (daily system ops), not archival:
- API keys can be rotated from provider dashboards
- Database passwords can be reset
- Service credentials can be regenerated

If all YubiKeys are lost (catastrophic overnight disaster), recovery is:
1. Get new YubiKeys
2. Log into each service dashboard
3. Rotate/regenerate credentials
4. Rebuild nix config

Annoying, not catastrophic.

## Future: Irreplaceable Secrets

If ever needed, add N+1 backup key:
- Store offsite (bank safe deposit box)
- Add as recipient for sensitive secrets only
- Store those `.age` files privately (not public dotfiles)

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

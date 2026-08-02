# CLAUDE.md

@CLAUDE-HOST.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

NixOS/nix-darwin/Home Manager flake managing every machine I own. Built on
**flake-parts** + **import-tree**: `flake.nix` is a stub, and everything under
`autoimport/` is loaded automatically as a flake-parts module.

See [`autoimport/README.md`](autoimport/README.md) for the authoritative
architecture notes — it is maintained alongside the code, this file is the
orientation layer.

## Architecture

### Directory structure

Everything real lives under `autoimport/`. Each file contributes to flake-parts
options; there is no central list of imports to update.

- **`autoimport/modules/`** — the meat. Reusable modules, grouped by topic
  (`cli.nix`, `graphical/`, `secrets/`, `storage/`, ...).
- **`autoimport/modules/hosts/`** — one file per machine, wiring role modules together.
- **`autoimport/packages/`** — custom derivations.
- **`autoimport/lab/`** — VM lab (see below).
- **`autoimport/templates/`** — `nix flake init` templates.

**Directories and files prefixed with `_` are skipped by import-tree.** That is
how non-module data is stored next to modules: `_host-specific/` (hardware
configs, disko layouts), `_age/` (encrypted secrets), `_derivations/`,
`_pubkeys.nix`. If you add a file that is *not* a flake-parts module, it must be
`_`-prefixed or it will be imported and fail.

### Module classes

Modules are published under `flake.modules.<class>.<name>` and merged across
files — many files can contribute to the same module name.

- `generic` — shared between NixOS and Darwin
- `nixos`, `darwin` — system-level
- `homeManager` — user-level

Current NixOS roles: `base`, `dev`, `graphical`, `homeServer`, `secrets`,
`theme`, `amdGpu`.

Use `jlib.mkHomeManager { generic, nixos, darwin }` for Home Manager modules that
need per-platform branches — it does conditional imports via the `system`
specialArg, because `imports` cannot depend on `config`/`pkgs`.

### Invariants

- Every host must declare `jl.system`.
- Never set `nixpkgs.overlays`/`nixpkgs.config` in a host or module. NixOS configs
  import `readOnlyPkgs`, and `pkgs` comes from the central flake-parts registry via
  `withSystem` (see `autoimport/modules/pkgs-override.nix`). Add overlays in the
  `perSystem` block there.
- All Home Manager modules get the `system` specialArg for use with `withSystem`.

### Hosts

| Host | Kind | Notes |
| --- | --- | --- |
| `desktop` | NixOS, x86_64 | Full graphical workstation (niri/hyprland), YubiKey-gated secrets |
| `server` | NixOS, x86_64 | Headless 24/7 `homeServer` role, deployed with deploy-rs |
| `server-mini` | NixOS, x86_64 | Second small server |
| `iso` | NixOS, x86_64 | Bootstrap installer ISO for nixos-anywhere |
| `macbook` | nix-darwin, aarch64 | Personal laptop |
| `macbook-work` | nix-darwin, aarch64 | Imports `homeModules.work` from the private repo |
| `developer@cloud-vm` | Home Manager only | Standalone HM for cloud dev boxes |

## Common commands

- **Home Manager restart**: `sudo systemctl restart home-manager-jeanluc`
- **Deploy server**: `deploy .#server` (only `server` is a deploy-rs node)
- **Validate**: `nix flake check`
- **Build a host without switching**: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`

Evaluation is cross-platform: `nix eval` of an `x86_64-linux` host works fine from
the macbook, so type errors can be caught without a Linux builder. Only *building*
needs the right platform.

## VM lab (`autoimport/lab/`)

Boots the real host roles as networked QEMU VMs so config changes can be validated
end to end before touching hardware.

```
nix build .#checks.x86_64-linux.lab-home-lan   # run assertions, pass/fail
nix run   .#lab-home-lan                       # interactive driver REPL
```

Requires a Linux host with `/dev/kvm` — in practice `desktop`. Nodes land on
`192.168.1.0/24` with the real short hostnames, so subnet-scoped ACLs behave as
they do IRL.

The lab works because nixpkgs' test framework re-evaluates each node through
`qemu-vm.nix`, which `mkVMOverride`s `fileSystems`/`swapDevices`/bootloader. **This
only holds if lab nodes import role modules (`base`, `homeServer`, ...) and never
the `_host-specific` hardware trees.** Keep hardware out of role modules.

Not covered: `secrets` (needs a YubiKey touch), `graphical`, and Darwin hosts
(cannot be VM nodes).

## Secrets

agenix. Encrypted files in `autoimport/modules/secrets/_age/`, recipients in
`autoimport/modules/secrets/_age/secrets.nix`, public keys centralised in
`autoimport/modules/secrets/_pubkeys.nix` (exposed as `flake.pubkeys`).

Secrets are decrypted with **YubiKey-backed age identities** (PIV), so decryption
needs a PIN + touch. On Darwin run `delock` to mount them.

The server is keyless and cannot be an agenix recipient. Instead,
`deposit-secrets` (see `secrets/secret-deposit.nix`) decrypts locally behind the
hardware key and pushes plaintext over SSH to the server. Configure via
`jl.secretDeposit.targets`.

## Private configuration

Work config lives in a separate private repo `dotfiles-private` (flake input via
`git+ssh`), expected at `../dotfiles-private`. It exports `homeModules.work`,
imported by `macbook-work`. Put anything work-private there.

## Remote server commands

- Run remote commands to inspect the server: `ssh server <cmd>`
- The server uses nushell — use nushell syntax in those commands.

## General notes

- I primarily use nushell interactively. Config is in `autoimport/modules/nushell/`.
- **Use `manix` to search Nix packages and options**:
  - `manix <query>` — nixpkgs packages, NixOS / Home Manager / nix-darwin options
  - `manix <query> --source nixpkgs_tree` — packages only
  - `manix <query> --source hm_options` — Home Manager options only
  - `manix <query> --source nd_options` — nix-darwin options only

## Version control with yadm

**This repo is tracked by yadm, not a standalone git/jj repo** — there is no `.git`
here and `jj` will not work. (This overrides the global "we use jj" instruction.)

- **Semi-automated commit workflow**:
  1. `yadm status` to see modified files
  1. `yadm ls-files --others --exclude-standard ~/nix/` to see untracked files
  1. `yadm diff` to review changes
  1. Group related changes by functional purpose — files implementing the same
     feature/fix get committed together (e.g. adding git hooks to all templates =
     one commit)
  1. **Manual handling required ONLY when** a single file mixes multiple unrelated
     changes — then tell me: "This file has multiple unrelated changes. Please use
     `yadm add -p <file>` to stage selectively"
  1. `yadm add <files>` and `yadm commit -m "<scope>: <description>"`
- **IMPORTANT**: Never run `yadm add -A` (adds literally everything to yadm)
- **flake.lock handling**: never its own commit — bundle with a related change
- **Commit message format**: `<program/scope>: <brief description>`

### Example commits

- `claude: settings`
- `nvim: better pasting`
- `nu: git abbreviations`
- `nix: add pkgs`
- `hypridle: increase timeouts`

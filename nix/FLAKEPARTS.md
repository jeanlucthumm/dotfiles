# flakeparts migration

Working log for the migration to a flake-parts + import-tree architecture.

## Goal

Flatten `system/modules/` + `home/modules/` "foundation" files into a unified
`nix/modules/` tree, auto-discovered via `import-tree`.

## Architectural decisions

- **Profile axis**: `base`, `cli`, `server`, `dev`, `gui` — **flat à-la-carte**.
  Hosts list every profile they want explicitly. No inheritance chain. Wins
  predictability over conciseness.
- **OS axis**: use the flake-parts module *class* (`flake.modules.darwin.*`,
  `flake.modules.nixos.*`) for system-level. For homeManager-level OS-specific
  bits, named modules under `homeManager` class:
  `flake.modules.homeManager.{darwin,nixos}`.
- **Sub-module organization**: per-program directories. Each file *contributes*
  to the profile(s) it's part of (e.g., `modules/nushell/cli.nix` writes to
  `flake.modules.homeManager.cli`). No relative imports — flake-parts merges
  by name, so multiple files can extend the same profile slot.
- **Underscore prefix** = `import-tree` skips (reserve for internal helpers).

## Status

Branch: `flakeparts`.

### Done

- Added `flake-parts` + `import-tree` flake inputs (declared, not yet wired
  into `flake.nix` outputs)
- New top-level `nix/modules/` with: `base.nix`, `cli.nix`, `dev.nix`,
  `graphical.nix`, `hosts.nix`, `jeanluc.nix`, `ssh.nix`
- Subtrees under `nix/modules/`: `secrets/`, `theme/`
- Removed old scattered foundation files (`system/modules/foundation.nix`,
  `home/modules/{darwin,nixos}/foundation.nix`, etc.)
- Macbook host fully factored into new modules layout (in `modules/hosts.nix`)
- **Nushell migration complete** — all `.nu` files + `cli.nix` / `dev.nix` /
  `darwin.nix` / `nixos.nix` under `modules/nushell/`. Old
  `home/programs/nushell/` and `home/modules/darwin/nushell.nix` removed.
  `nrs`/`nra` defs moved out of `base.nix` into the right per-OS contributions
  and switched from `configFile.text` to `extraConfig` (the former clobbered
  the base config).

### In progress

(nothing active)

### TODO

- **Wire `flake.nix` outputs to flake-parts** (`mkFlake` + `imports = [(import-tree ./modules)]`).
  Until done, the new `modules/hosts.nix` darwinConfiguration is dead code and
  the modules tree can't be eval-verified. Old `flake.nix` macbook config
  references deleted files and will fail to evaluate — that's expected.
- Migrate remaining programs to the new layout (fish, starship, taskwarrior,
  hyprland, niri, hammerspoon, …)
- Migrate other host configs (desktop, server, server-mini, virtual, cloud-vm,
  iso) once flake.nix is rewired

## Reference

[mightyiam/infra](https://github.com/mightyiam/infra) — clean flake-parts +
import-tree reference. Cloned locally at `/tmp/infra`.

## Log

- 2026-04-26: log started; resuming from clean tree on `flakeparts`
- 2026-04-26: locked in flat-profile architectural decision; completed nushell
  migration (cli/dev/darwin/nixos contributions, all .nu files moved, old
  files deleted, base.nix de-nushelled, macbook host imports updated to
  `[base cli dev gui darwin]`). Verification deferred until `flake.nix` is
  rewired to use flake-parts.

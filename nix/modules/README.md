# Modules directory

## Flake parts module breakdown

Each individual nix file contributes to a far smaller set of top level modules in
`config.flake.modules`. Hosts compose by pulling from that small set _within nix_ (not by importing
the nix file!). Nix files are purely for organization and are never imported directly.
Instead, `import-tree` imports the entire `/modules/**/*` directory, evaluating every file.

## Top level module sets

- **base** — Baseline usable config. Includes stuff like CLI, but relatively barebones
- **dev** – Adds configs for development. Meant for daily use
- **graphical** – For daily machines with a GUI
- **secrets** — For machines with a hwkey that are able to unlock and use repo secrets
- **theme** — Themeing via stylix and custom

## Config trees

Each module set spans across multiple config trees, e.g. the nixos config tree, or the nix-darwin one. A nix file typically groups the settings for one logical unit across these trees.

We use a special helper `jlib.mkHomeManager` to ergonomically declare home manager config meant for
generic, darwin, or NixOS. This works around the limitation that `flake.modules.homeManager` needs
to only contain modules so we cannot subdivide by host class.

# Auto-import directory

Everything in here gets automatically imported into the top level flake eval (via `import-tree`)
and each file contributes to a small set of flake-parts modules.

More details in the root README.md.

## Directory structure

For now, I'm mirroring the directory to match flake outputs. Namely, `modules` for flake-parts
modules (which is the meat of the config), packages for custom derivations I'm too lazy to PR
into nixpkgs, templates, and so on.

## The `jlib` library

I put custom utils under `jlib` attrs (see [here](./modules/jlib.nix)).

There's also `jlib.system` which takes care of all the crazy `pkgs` hacks. (see
the file comment [here](./modules/pkgs-override.nix).

`jlib` because Jean-Luc (me) -> JL -> JL Library -> jlib

## Invariants

- Every host needs to declare `jl.system`
- All home manager modules have access to specialArg `system` to be used for `withSystem`

# Auto-import directory

Everything in here gets automatically imported into the top level flake eval (via `import-tree`)
and each file contributes to a small set of flake-parts modules.

## Directory structure

For now, I'm mirroring the directory to match flake outputs. Namely, `modules` for flake-parts
modules (which is the meat of the config), `packages` for custom derivations I'm too lazy to PR
into nixpkgs, `templates`, and so on.

## The `jlib` library

I put custom utils under `jlib` attrs (see [here](./modules/jlib.nix)).

There's also `jlib.system` which takes care of all the crazy `pkgs` hacks. ([here](./modules/pkgs-override.nix))

`jlib` because Jean-Luc (me) -> JL -> JL Library -> jlib

## `pkgs` hacks

Because there's so many different configs being evaluated (nixos, darwin, home-manager, flake, ...)
if you're not careful you end up evaluating pkgs for the same system multiple times.

Flake-parts fixes this by creating a central "registry" for pkgs for each system, accessible via
`perSystem` and `withSystem`.

The `jlib.system` setup mentioned above ensures that module evals always pull pkgs from this central
registry end that they do not modify nixpkgs themselves.

## Invariants

- Every host needs to declare `jl.system`
- All home manager modules have access to specialArg `system` to be used for `withSystem`

# Standalone Home Manager hosts live under `flake.homeConfigurations`.
# flake-parts declares nixosConfigurations and (through nix-darwin's flake
# module) darwinConfigurations, but not this one, and a freeform attribute can
# only be defined once: without an option, two host files defining it cannot
# be merged.
{
  lib,
  flake-parts-lib,
  ...
}: {
  options.flake = flake-parts-lib.mkSubmoduleOptions {
    homeConfigurations = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = {};
      description = "Standalone Home Manager hosts, keyed `user@host`.";
    };
  };
}

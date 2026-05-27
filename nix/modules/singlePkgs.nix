{
  inputs,
  withSystem,
  ...
}: {
  flake.modules.generic.base = {
    config,
    lib,
    ...
  }: {
    import = [
      # No local tree modifications of nixpkgs so we have the same pkgsc
      inputs.nixpkgs.nixosModules.readOnlyPkgs
    ];

    options.jl.system = lib.mkOption {
      type = lib.types.string;
      description = "System string";
    };

    config = {
      nixpkgs.hostPlatform = config.jl.system;
      # Avoid evaluating `pkgs` multiple times by importing the one from flake-parts
      # for this system.
      nixpkgs.pkgs = withSystem config.jl.system ({pkgs, ...}: pkgs);
    };
  };
}

# Collection of all host outputs.
#
# This is the entry point for system config.
{
  config,
  inputs,
  lib,
  ...
}: {
  flake.darwinConfigurations."macbook" = inputs.nix-darwin.lib.darwinSystem {
    modules = with config.flake.modules; [
      darwin.base
      {
        home-manager.users.jeanluc.imports = [
          homeManager.base
        ];
      }
      # TODO: overlays
    ];
  };
}

# Collection of all host outputs.
#
# This is the entry point for system config.
{
  config,
  inputs,
  ...
}: {
  flake.darwinConfigurations."macbook" = inputs.nix-darwin.lib.darwinSystem {
    modules = with config.flake.modules; [
      generic.jeanluc
      darwin.base
      darwin.theme
      darwin.secrets
      darwin.ssh
      darwin.nushell
      darwin.graphical
      darwin.dev
      {
        networking.hostName = "macbook";

        # Home Manager module tree
        home-manager.users.jeanluc.imports = [
          homeManager.base
        ];

        # What devices can SSH?
        users.users.jeanluc.openssh.authorizedKeys.keys = with config.flake.pubkeys; [
          desktop.fido2.auth
          phone
        ];

        theme = {
          name = "rose-pine";
          darkMode = false;
        };

        system.stateVersion = 4;
        system.primaryUser = "jeanluc";
        nixpkgs.hostPlatform = "aarch64-darwin";
      }
      # TODO: overlays
    ];
  };
}

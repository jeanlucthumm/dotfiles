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
      darwin.cli
      darwin.graphical
      darwin.dev
      {
        networking.hostName = "macbook";

        # Home Manager module tree (flat à la carte composition)
        home-manager.users.jeanluc.imports = with config.flake.modules.homeManager; [
          base
          cli
          dev
          graphical
          darwin
          secrets
          theme
          {
            # Security identity
            programs.git.signing = {
              key = "~/.ssh/id_ed25519_sk_signing";
              format = "ssh";
            };

            age.identityPaths = [
              ./macbook-yubikey-identity.txt
            ];
          }
        ];

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

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
      darwin.base
      darwin.dev
      darwin.graphical
      darwin.secrets
      darwin.theme

      # Avoid evaluating `pkgs` multiple times by importing the one from flake-parts
      # for this system (via `withSystem`). Also freeze pkgs to avoid surprising local tree
      # only modifications.
      inputs.nixpkgs.nixosModules.readOnlyPkgs
      {
        nixpkgs.hostPlatform = "aarch64-darwin";
        nixpkgs.pkgs = withSystem "aarch64-darwin" ({pkgs, ...}: pkgs);
      }

      {
        networking.hostName = "macbook";

        home-manager.users.jeanluc.imports = with config.flake.modules.homeManager; [
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
      }
      # TODO: overlays
    ];
  };
}

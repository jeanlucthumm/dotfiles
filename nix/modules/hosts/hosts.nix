# Collection of all host outputs.
#
# This is the entry point for system config.
{
  config,
  inputs,
  ...
}: {
  flake.darwinConfigurations."macbook" = inputs.nix-darwin.lib.darwinSystem {
    modules = with config.flake.modules.darwin; let
      themeSetting = {
        name = "rose-pine";
        darkMode = false;
      };
    in [
      base
      dev
      graphical
      secrets
      theme
      {
        networking.hostName = "macbook";
        jl.system = "aarch64-darwin";

        home-manager.users.jeanluc.imports = [
          {
            # Security identity
            programs.git.signing = {
              key = "~/.ssh/id_ed25519_sk_signing";
              format = "ssh";
            };

            age.identityPaths = [
              ./macbook-yubikey-identity.txt
            ];

            theme = themeSetting;
          }
        ];

        users.users.jeanluc.openssh.authorizedKeys.keys = with config.flake.pubkeys; [
          desktop.fido2.auth
          phone
        ];

        theme = themeSetting;

        system.stateVersion = 4;
        system.primaryUser = "jeanluc";
      }
      # TODO: overlays
    ];
  };
}

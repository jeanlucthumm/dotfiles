fp: {
  flake.darwinConfigurations."macmini" = fp.inputs.nix-darwin.lib.darwinSystem {
    modules = with fp.config.flake.modules.darwin; [
      base
      {
        networking.hostName = "macmini";
        jl.system = "aarch64-darwin";
        # Nix installers newer than the macbook's create nixbld at 350, not 30000.
        ids.gids.nixbld = 350;
        users.users.jeanluc.openssh.authorizedKeys.keys = with fp.config.flake.pubkeys; [
          desktop.fido2.auth
          macbook.fido2.auth
          phone
        ];

        # Headless iCloud/Syncthing bridge: both daemons live in a user session,
        # so stay logged in and awake. Auto-login only takes effect once it has
        # been switched on in System Settings (that writes /etc/kcpassword).
        system.defaults = {
          loginwindow.autoLoginUser = "jeanluc";
          screensaver.askForPassword = true;
          screensaver.askForPasswordDelay = 0;
        };
        power = {
          sleep.computer = "never";
          restartAfterPowerFailure = true;
          # Auto-login boots to an open desktop, so lock it soon after idle.
          sleep.display = 10;
        };

        # Standalone build (not App Store): tailscaled runs as a system daemon,
        # so the tailnet is up before anyone logs in. Not managed by nix on
        # Darwin on purpose; the macbook has the same app installed by hand.
        homebrew.casks = ["tailscale-app"];

        system.stateVersion = 4;
        system.primaryUser = "jeanluc";

        home-manager.users.jeanluc.imports = [
          {
            jl.syncthing.enable = true;

            home.stateVersion = "24.05";
          }
        ];
      }
    ];
  };
}

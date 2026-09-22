fp: {
  flake.darwinConfigurations."macmini" = fp.inputs.nix-darwin.lib.darwinSystem {
    modules = with fp.config.flake.modules.darwin; [
      base
      {
        networking.hostName = "macmini";
        jl.system = "aarch64-darwin";
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

        system.stateVersion = 4;
        system.primaryUser = "jeanluc";

        home-manager.users.jeanluc.imports = [
          {
            home.stateVersion = "24.05";
          }
        ];
      }
    ];
  };
}

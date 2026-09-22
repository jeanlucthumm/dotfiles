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

        system.stateVersion = 4;
        system.primaryUser = "jeanluc";

        # Headless iCloud/Syncthing bridge: both daemons live in a user session,
        # so stay logged in and awake. Auto-login only takes effect once it has
        # been switched on in System Settings (that writes /etc/kcpassword).
        system.defaults.loginwindow.autoLoginUser = "jeanluc";
        power.sleep.computer = "never";
        power.restartAfterPowerFailure = true;
        # Auto-login boots to an open desktop, so lock it soon after idle.
        power.sleep.display = 10;
        system.defaults.screensaver.askForPassword = true;
        system.defaults.screensaver.askForPasswordDelay = 0;

        home-manager.users.jeanluc.imports = [
          {
            home.stateVersion = "24.05";
          }
        ];
      }
    ];
  };
}

fp: {
  flake.darwinConfigurations."macbook-work" = fp.inputs.nix-darwin.lib.darwinSystem {
    modules = with fp.config.flake.modules.darwin; [
      base
      dev
      graphical
      theme
      {
        networking.hostName = "macbook-work";
        jl.system = "aarch64-darwin";
        users.users.jeanluc.openssh.authorizedKeys.keys = with config.flake.pubkeys; [
          desktop.fido2.auth
          phone
        ];
        theme = fp.jlib.withLocalThemeOverride {
          name = "rose-pine";
          darkMode = false;
        };

        # =====================

        # TODO: seperate out
        # Determinate Nix manages nix settings
        # nix.enable = false;

        # stylix.homeManagerIntegration.followSystem = false;
        # stylix.enableReleaseChecks = false;

        # system.stateVersion = 4;
        # system.primaryUser = "jeanlucthumm";

        # ids.gids.nixbld = 350;

        # nixpkgs.config.allowUnfree = true;
        # nixpkgs.hostPlatform = "aarch64-darwin";

        # users.users.jeanlucthumm = {
        #   name = "jeanlucthumm";
        #   home = "/Users/jeanlucthumm";
        # };

        # environment.shells = ["/etc/profiles/per-user/jeanlucthumm/bin/nu"];

        # home-manager.sharedModules = [./theme-setting.nix];
      }
    ];
  };
}

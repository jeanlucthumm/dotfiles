fp @ {jlib, ...}: {
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
        theme = jlib.withLocalThemeOverride {
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

        # =========== HOME MANAGER

        # imports = [
        #   ../modules/darwin/foundation.nix
        #   ../modules/darwin/nushell.nix
        #   ../modules/cli
        #   ../modules/graphical.nix
        #   ../modules/darwin/graphical.nix
        #   ../modules/llm.nix
        #   ../modules/theme-home.nix
        #   # ssh.nix not imported — work SSH config is handled by dotfiles-private
        #   ../programs/taskwarrior/common.nix
        #   inputs.dotfiles-private.homeModules.work
        # ];

        # home.packages = with pkgs; [_1password-cli pnpm ngrok google-cloud-sdk sem];

        # # No FIDO2 security key on work laptop — waiting for sk setup on this host
        # programs.git.signing.signByDefault = lib.mkForce false;
        # programs.git.signing.format = null;

        # gtk.gtk4.theme = null;

        # home.stateVersion = "24.05";
      }
    ];
  };
}

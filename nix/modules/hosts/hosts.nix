fp: {
  flake.darwinConfigurations."macbook" = fp.inputs.nix-darwin.lib.darwinSystem {
    modules = with fp.config.flake.modules.darwin; [
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
            age.identityPaths = [
              ./_host-specific/macbook/yubikey-identity.txt
            ];
          }
        ];
        users.users.jeanluc.openssh.authorizedKeys.keys = with config.flake.pubkeys; [
          desktop.fido2.auth
          phone
        ];
        theme = fp.jlib.withLocalThemeOverride {
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

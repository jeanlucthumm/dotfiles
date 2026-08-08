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

        home-manager.users.jeanluc.imports = [
          {
            home.stateVersion = "24.05";
          }
        ];
      }
    ];
  };
}

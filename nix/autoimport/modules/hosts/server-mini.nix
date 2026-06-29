fp: {
  flake.nixosConfigurations."server-mini" = fp.inputs.nixpkgs.lib.nixosSystem {
    modules = with fp.config.flake.modules.nixos; [
      base
      ({pkgs, ...}: {
        imports = [./_host-specific/server-mini];

        networking.hostName = "server-mini";
        networking.hostId = "3333bb65";
        jl.system = "x86_64-linux";

        swapDevices = [
          {
            device = "/swapfile";
            size = 8 * 1024;
          }
        ];

        users.users.root.openssh.authorizedKeys.keys = with fp.config.flake.pubkeys; [
          desktop.fido2.auth
          macbook.fido2.auth
          phone
        ];
        users.users.jeanluc.openssh.authorizedKeys.keys = with fp.config.flake.pubkeys; [
          desktop.fido2.auth
          macbook.fido2.auth
          phone
        ];

        boot.supportedFilesystems = ["zfs"];
        environment.systemPackages = [pkgs.zfs];

        system.stateVersion = "24.05";

        home-manager.users.jeanluc = {
          home.stateVersion = "24.05";
        };
      })
    ];
  };
}

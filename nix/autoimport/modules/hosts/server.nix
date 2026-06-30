{
  config,
  inputs,
  ...
}: {
  flake.nixosConfigurations."server" = inputs.nixpkgs.lib.nixosSystem {
    modules = with config.flake.modules.nixos; [
      base
      homeServer
      {
        imports = [./_host-specific/server];

        networking.hostName = "server";
        networking.hostId = "1d9f895e";
        jl.system = "x86_64-linux";

        # TODO: figure out the secrets story for server
        # age.identityPaths = [
        #   "/home/jeanluc/.ssh/id_ed25519"
        # ];

        swapDevices = [
          {
            device = "/swapfile";
            size = 8 * 1024; # 8 GiB
          }
        ];

        users.users.root.openssh.authorizedKeys.keys = with config.flake.pubkeys; [
          desktop.fido2.auth
          macbook.fido2.auth
          phone
        ];

        users.users.jeanluc.openssh.authorizedKeys.keys = with config.flake.pubkeys; [
          desktop.fido2.auth
          macbook.fido2.auth
          phone
        ];

        services.atd.enable = true;

        system.stateVersion = "24.05";

        home-manager.users.jeanluc = {
          # TODO directly use the reddit-easy-post flake output
          # home.packages = with pkgs; [
          #   reddit-easy-post # YAML to Reddit posting CLI
          # ];

          home.stateVersion = "24.05";
        };
      }
    ];
  };
}

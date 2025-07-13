{...}: {
  imports = [
    ./disko-config.nix
    ../../modules/foundation.nix
    ../../modules/security.nix
    ../../modules/ssh.nix
    ../../modules/tailscale.nix
    ../../modules/user-jeanluc.nix
    ../../modules/boot.nix
    ../../modules/containers.nix
    ../../modules/home-assistant.nix
  ];

  networking.hostName = "server";
  networking.hostId = "1d9f895e";

  swapDevices = [
    {
      device = "/swapfile";
      size = 8 * 1024; # 8 GiB
    }
  ];
  system.stateVersion = "24.05";
}

{...}: {
  imports = [
    ../../modules/nixos-foundation.nix
    ../../modules/security.nix
    ../../modules/ssh.nix
    ../../modules/tailscale.nix
    ../../modules/user-jeanluc.nix
    ../../modules/boot.nix
    ./theme-setting.nix
  ];

  networking.hostName = "server";

  # Allows home manager modules to access theme
  home-manager.sharedModules = [./theme-setting.nix];

  swapDevices = [
    {
      device = "/swapfile";
      size = 8 * 1024; # 8 GiB
    }
  ];
  system.stateVersion = "24.05";
}

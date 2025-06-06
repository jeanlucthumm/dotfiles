{pkgs, ...}: {
  imports = [
    ../../modules/bluetooth.nix
    ../../modules/graphical.nix
    ../../modules/nixos-foundation.nix
    ../../modules/nixos-graphical.nix
    ../../modules/security.nix
    ../../modules/ssh.nix
    ../../modules/tailscale.nix
    ../../modules/user-jeanluc.nix
    ../../modules/boot.nix
    ../../modules/amd-gpu.nix
    ./hardware-configuration.nix
    ./theme-setting.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      # Disables AMDGPU Scatter/Gather display functionality to fix screen
      # flickering issues on Ryzen systems (especially 7000 series APUs).
      "amdgpu.sg_display=0"
    ];
  };

  networking.hostName = "desktop";

  nixpkgs.config.allowUnfree = true;

  # Android Debug Bridge (ADB) for Android development
  programs.adb.enable = true;

  swapDevices = [
    {
      device = "/swapfile";
      size = 32 * 1024; # 32 GiB
    }
  ];

  # Software that runs in the background
  services = {
    # Platform agnostic pkg manager. Useful for installing stuff that has poor Nix support.
    flatpak.enable = true;
    # Schedule tasks to run at specific times using `at` command
    atd = {
      enable = true;
      allowEveryone = true;
    };
  };

  xdg.portal = {
    # Desktop integration portal for sandboxed apps (flatpak) to work correctly
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
    config.common.default = "gtk";
  };

  # This is a systemd service that delays system boot until network connectivity is established.
  # Disabling speeds up boot time, but need to make sure nothing requires immediate network
  # connectivity
  systemd.services.NetworkManager-wait-online.enable = false;

  # Docker is a container platform
  virtualisation.docker.enable = true;

  # Allows home manager modules to access theme
  home-manager.sharedModules = [./theme-setting.nix];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}

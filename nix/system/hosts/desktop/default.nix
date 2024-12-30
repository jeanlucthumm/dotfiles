{pkgs, ...}: {
  imports = [
    ../../modules/nixos-foundation.nix
    ../../modules/nixos-graphical.nix
    ../../modules/graphical.nix
    ../../modules/bluetooth.nix
    ../../modules/security.nix
    ../../theme-setting.nix
    ./hardware-configuration.nix
    ./theme-setting.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    kernelParams = [
      # Disables AMDGPU Scatter/Gather display functionality to fix screen
      # flickering issues on Ryzen systems (especially 7000 series APUs).
      "amdgpu.sg_display=0"

      # Needed for VPNs
      "net.ipv4.ip_forward=1"
    ];

    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        edk2-uefi-shell.enable = true;
      };
    };
  };

  networking = {
    hostName = "desktop";
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH
      ];
      allowedUDPPorts = [
        41641 # Tailscale
        1194 # OpenVPN
      ];
      checkReversePath = false; # Set to false to allow Tailscale
    };
  };

  users.users.jeanluc = {
    isNormalUser = true;
    description = "Jean-Luc Thumm";
    extraGroups = [
      "networkmanager"
      "wheel"
      # Android Debug Bridge unprivileged access
      "adbusers"
      # Docker without sudo
      "docker"
    ];
    shell = pkgs.nushell;
  };

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
    # Widely used SSH client/server
    openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
    };
    # Easy to use VPN for all your devices
    tailscale.enable = true;
    # Handles storage devices and provides D-bus interface
    udisks2.enable = true;
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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}

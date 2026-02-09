{pkgs, ...}: {
  imports = [
    ../../modules/bluetooth.nix
    ../../modules/containers.nix
    ../../modules/graphical.nix
    ../../modules/foundation.nix
    ../../modules/graphical.nix
    ../../modules/security.nix
    ../../modules/ssh.nix
    ../../modules/tailscale.nix
    ../../modules/user-jeanluc.nix
    ../../modules/boot.nix
    ../../modules/amd-gpu.nix
    ../../modules/agenix.nix
    ../../modules/theme-system.nix
    ../../modules/secrets.nix
    ../../modules/neo4j.nix
    ../../modules/logitech-mx.nix
    ./hardware-configuration.nix
    ./theme-setting.nix
  ];

  boot = {
    kernelParams = [
      # Disables AMDGPU Scatter/Gather display functionality to fix screen
      # flickering issues on Ryzen systems (especially 7000 series APUs).
      "amdgpu.sg_display=0"
    ];
  };

  age = {
    identityPaths = [
      ../../../secrets/desktop-yubikey-identity.txt
    ];
    # age needs age-plugin-yubikey in PATH during activation, before system PATH is set
    ageBin = "${pkgs.writeShellScript "age-with-yubikey" ''
      export PATH="${pkgs.age-plugin-yubikey}/bin:$PATH"
      exec ${pkgs.age}/bin/age "$@"
    ''}";
  };

  networking.hostName = "desktop";
  networking.hostId = "17646629";

  # Block distracting websites
  networking.extraHosts = ''
    127.0.0.1 chess.com
    127.0.0.1 www.chess.com
    127.0.0.1 lichess.org
    127.0.0.1 www.lichess.org
  '';

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # Desktop host is the only one doing deployments.
    deploy-rs
    # Docker Compose alternative for Podman
    podman-compose
    # Android Debug Bridge (ADB) for Android development
    android-tools
  ];

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
    # PCSC daemon for smart card support (Yubikey)
    pcscd.enable = true;
    # Neo4j configuration
    neo4j.directories.home = "/var/lib/neo4j";
  };

  # XDG Desktop Portals: Secure gateways for apps to access system features.
  # In Wayland, apps can't directly capture the screen (security). Instead they request
  # access through portals which show permission dialogs and provide controlled access.
  # Without the right portal backend, screen recording apps like Kooha/OBS will fail with
  # "No such interface" errors. Each compositor needs its matching portal implementation.
  xdg.portal = {
    # Desktop integration portal for sandboxed apps (flatpak) to work correctly
    # xdg-desktop-portal-wlr provides screen recording support for wlroots-based compositors like niri
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk # File choosers, notifications, general GTK stuff
      pkgs.xdg-desktop-portal-wlr # ScreenCast/Screenshot for niri (wlroots-based)
    ];
    config = {
      common.default = "gtk";
      # Route specific portal interfaces to the right backend for niri
      niri = {
        default = "gtk";
        "org.freedesktop.impl.portal.ScreenCast" = "wlr"; # Screen recording/sharing
        "org.freedesktop.impl.portal.Screenshot" = "wlr"; # Screenshots
      };
    };
  };

  # This is a systemd service that delays system boot until network connectivity is established.
  # Disabling speeds up boot time, but need to make sure nothing requires immediate network
  # connectivity
  systemd.services.NetworkManager-wait-online.enable = false;


  # Ensure Neo4j data directory exists
  systemd.tmpfiles.rules = [
    "d /var/lib/neo4j 0755 neo4j neo4j -"
  ];

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

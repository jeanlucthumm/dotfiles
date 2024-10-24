{
  config,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../default-nixos
    ./theme-setting.nix
  ];

  networking.hostName = "desktop"; # Define your hostname.
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22 # SSH
    ];
    allowedUDPPorts = [
      41641 # Tailscale
    ];
    checkReversePath = false; # Set to false to allow Tailscale
  };

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

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

  programs.adb.enable = true;

  swapDevices = [
    {
      device = "/swapfile";
      size = 32 * 1024; # 32 GiB
    }
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };
  services.tailscale.enable = true;
  services.udisks2.enable = true;

  # This is a systemd service that delays system boot until network connectivity is established.
  # Disabling speeds up boot time, but need to make sure nothing requires immediate network
  # connectivity
  systemd.services.NetworkManager-wait-online.enable = false;

  environment.systemPackages = with pkgs; [
    neovim
    yadm
    tmux
    fish
    git
  ];

  virtualisation.docker.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}

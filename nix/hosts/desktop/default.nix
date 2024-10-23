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

  environment.systemPackages = with pkgs; [
    neovim
    yadm
    tmux
    fish
    git
  ];

  # System-wide themeing
  stylix = let
    t = config.theme.name;
    d = config.theme.darkMode;
  in {
    enable = true;
    image =
      if t == "gruvbox"
      then
        # Always dark wallpaper since we want contrast
        ../../wallpapers/gruvbox/dark/great-wave-of-kanagawa-gruvbox.png
      else throw "unknown theme ${t}";
    polarity =
      if d
      then "dark"
      else "light";
    base16Scheme =
      if t == "gruvbox"
      then
        if d
        then "${pkgs.base16-schemes}/share/themes/gruvbox-material-dark-soft.yaml"
        else "${pkgs.base16-schemes}/share/themes/gruvbox-material-light-soft.yaml"
      else throw "unknown theme ${t}";
    fonts = let
      fontPkg = pkgs.nerdfonts.override {
        # Narrow down since all of nerdfonts is a lot.
        fonts = ["JetBrainsMono" "FiraCode"];
      };
    in {
      monospace = {
        package = fontPkg;
        name = "JetBrainsMono Nerd Font Mono";
      };
      sizes = {
        applications = 10;
      };
    };
  };

  virtualisation.docker.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}

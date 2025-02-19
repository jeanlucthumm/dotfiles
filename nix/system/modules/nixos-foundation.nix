# Foundational NixOS settings
{pkgs, ...}: {
  # Enable flakes
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Modules will add ports as needed to firewall config
  networking.firewall.enable = true;

  # Timezone and locale
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Stuff that runs in the background
  services = {
    # Configure keymap in X11;
    xserver.xkb = {
      layout = "us";
      variant = "";
    };
    # Enables UPower which provides power info and control via dbus to applications
    upower.enable = true;
    # Handles storage devices and provides D-bus interface
    udisks2.enable = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  security.sudo = {
    execWheelOnly = true;
    wheelNeedsPassword = false;
  };

  # Basic sytem wide packages
  environment.systemPackages = with pkgs; [
    file # Figure out what a certain file is
    lsof # Open files (but good for ports)
    tmux # Terminal multiplexer
    git # Version control
    nushell # Shell so I don't have to use bash for sysadmin
    yadm # Dotfile manager
  ];

  # Nix store gets full of old stuff, so clean it up periodically.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}

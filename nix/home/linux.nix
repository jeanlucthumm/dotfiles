{
  config,
  pkgs,
  # Passed via extraSpecialArgs in flake.nix
  hostName,
  ...
}: let
  homeDir = config.home.homeDirectory;
in {
  imports = [
    ./modules/common.nix
    ./modules/hyprland.nix
    ./theme-home.nix
  ];

  home.packages = with pkgs; [
    # Desktop
    android-studio # Android development
    signal-desktop # Encrypted messaging
    meld # Diff tool
    gammastep # Redshifting at night
    nemo # File browser
    brightnessctl # Screen brightness controls
    wl-clipboard # Copy paste in Wayland
    qutebrowser # Keyboard-centric browser
    bitwarden-desktop # Password management
    grim # Screenshots
    slurp # For selecting screen regions
    pavucontrol # GUI for PiperWire
    wev # Shows keycodes in wayland
    swayosd # Responsive UI for changing volume and such
    xdg-utils # Open files in right prorgram
    polkit_gnome # UI for Polkit authentication
    libnotify # Notifications
    libinput # Input device management
    firefox # Web browser
  ];

  programs = {
    # Bottom bar
    waybar.enable = true;
    # Program launcher
    wofi = {
      enable = true;
      settings = {
        width = 420;
        height = 550;
        location = "center";
        allow_images = true; # Icons for entries
        allow_markup = true;
        prompt = "Program";
        matching = "fuzzy";
        no_actions = true; # No expandable list under certain programs
        halign = "fill";
        orientation = "vertical";
        insensitive = true;
        image_size = 28;
      };
    };

    fish.shellAliases.nrs = "sudo nixos-rebuild switch --flake $HOME/nix#${hostName}";
    nushell.configFile.text = ''
      def nrs [] {
          sudo nixos-rebuild switch --flake $"($env.HOME)/nix#${hostName}"
      }
    '';

    qutebrowser = {
      # Uses VCS dotfiles
      enable = true;
      loadAutoconfig = true;
    };
  };

  xdg = {
    enable = true;

    userDirs = {
      enable = true;
      createDirectories = true;
      pictures = "${homeDir}/media";
      music = "${homeDir}/media";
      videos = "${homeDir}/media";
      desktop = null;
      publicShare = null;
      templates = null;
    };

    mimeApps = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/http" = ["firefox.desktop"];
        "x-scheme-handler/https" = ["firefox.desktop"];
        "text/html" = ["firefox.desktop"];
        "application/xhtml+xml" = ["firefox.desktop"];
      };
    };
  };

  services = {
    # TODO configure with stylix
    # hyprpaper.enable = true;
    swayosd.enable = true;
    # Redlight shifting at night
    gammastep = {
      enable = true;
      dawnTime = "06:00";
      duskTime = "22:00";
      temperature = {
        day = 6500;
        night = 3000;
      };
      provider = "geoclue2";
    };
    mako = {
      enable = true;
      markup = true;
      borderRadius = 10;
      icons = true;
      padding = "10";
    };
  };

  home.sessionVariables = {
    OS = "Linux";
    CHROME_EXECUTABLE = "${pkgs.ungoogled-chromium}/bin/chromium";
  };

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}

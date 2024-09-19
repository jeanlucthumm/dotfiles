{
  config,
  pkgs,
  lib,
  # Passed via extraSpecialArgs
  hostName,
  ...
}: let
  homeDir = config.home.homeDirectory;
  # TODO: HomeManager doesn't seem to have access to paths
  isArch = builtins.pathExists "/etc/arch-release";
in {
  imports = [
    ./modules/common.nix
    ./modules/hyprland.nix
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

    fish.shellAliases = lib.mkMerge [
      {
        udpate = "sudo nixos-rebuild switch --flake $HOME/nix#${hostName}";
      }
      (lib.mkIf
        isArch
        {
          pacman = "paru";
        })
    ];

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
        "x-scheme-handler/http" = ["org.qutebrowser.qutebrowser.desktop"];
        "x-scheme-handler/https" = ["org.qutebrowser.qutebrowser.desktop"];
        "text/html" = ["org.qutebrowser.qutebrowser.desktop"];
        "application/xhtml+xml" = ["org.qutebrowser.qutebrowser.desktop"];
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
    ANDROID_SDK_ROOT = "${homeDir}/Android/Sdk";
    ANDROID_HOME = config.home.sessionVariables.ANDROID_SDK_ROOT;
    CHROME_EXECUTABLE = "${pkgs.ungoogled-chromium}/bin/chromium";
  };

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}

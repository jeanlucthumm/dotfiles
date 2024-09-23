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
      style = ''
        window {
          border-radius: 20px;
          border: solid 2px;
        }

        #input {
          padding: 10px;
          margin: 20px;
          padding-left: 10px;
          padding-right: 10px;
          border-radius: 20px;
        }

        #input:focus {
          border: none;
          outline: none;
        }

        #inner-box {
          margin: 10px;
          margin-top: 0px;
          border-radius: 20px;
        }

        #outer-box {
          border: none;
        }

        #scroll {
          margin: 0px 10px 20px 10px;
        }

        #text:selected {
          color: #fff;
        }

        #img {
          background: transparent;
          margin-right: 10px;
          margin-left: 5px;
        }

        #entry {
          padding: 10px;
          border: none;
          border-radius: 20px;
        }

        #entry:selected {
          outline: none;
          border: none;
        }
      '';
    };

    fish.shellAliases = lib.mkMerge [
      {
        update = "sudo nixos-rebuild switch --flake $HOME/nix#${hostName}";
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

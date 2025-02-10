# NixOS specific GUI config
{
  config,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;
  configDir = config.xdg.configHome;
in {
  imports = [
    ../programs/hyprland.nix
  ];

  home.packages = with pkgs; [
    android-studio # Android development
    signal-desktop # Encrypted messaging
    meld # Diff tool
    gammastep # Redshifting at night
    nautilus # File browser
    brightnessctl # Screen brightness controls
    wl-clipboard # Copy paste in Wayland
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
    discord # Chat
    gimp # Image editing

    lmstudio # LLM experimentation
    tor-browser # Privacy browser
    google-cloud-sdk # Google Cloud CLI
    ungoogled-chromium # For Dart dev

    vscode # Literally only using this for Cline
    zed-editor # IDE
    code-cursor # Agentic IDE
    whatsapp-for-linux # Chat
    obsidian # Note taking
  ];

  programs = {
    mpv.enable = true;
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
    # Keyboard-centric browser
    qutebrowser = {
      # Uses VCS dotfiles
      enable = true;
      loadAutoconfig = true;
    };
  };

  gtk = {
    enable = true;
    # TODO: add again once resolved: https://github.com/NixOS/nixpkgs/issues/380227
    # iconTheme = {
    #   name = "Tela-circle";
    #   package = pkgs.tela-circle-icon-theme;
    # };
    cursorTheme = {
      name = "Oreo Blue Cursors";
      package = pkgs.oreo-cursors-plus;
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
        "x-scheme-handler/http" = ["zen.desktop"];
        "x-scheme-handler/https" = ["zen.desktop"];
        "text/html" = ["zen.desktop"];
        "application/xhtml+xml" = ["zen.desktop"];
      };
    };

    desktopEntries = {
      qutebrowser-work = {
        name = "Qutebrowser (Work)";
        genericName = "Web Browser";
        comment = "A keyboard-driven, vim-like browser based on Python and Qt (Work Profile)";
        icon = "qutebrowser";
        type = "Application";
        categories = ["Network" "WebBrowser"];
        exec = "qutebrowser --basedir ${configDir}/qutebrowser/profiles/work --untrusted-args %u";
        terminal = false;
        startupNotify = true;
        mimeType = [
          "text/html"
          "text/xml"
          "application/xhtml+xml"
          "application/xml"
          "application/rdf+xml"
          "image/gif"
          "image/webp"
          "image/jpeg"
          "image/png"
          "x-scheme-handler/http"
          "x-scheme-handler/https"
          "x-scheme-handler/qute"
        ];
        actions = {
          "new-window" = {
            name = "New Window";
            exec = "qutebrowser --basedir ${configDir}/qutebrowser/profiles/work";
          };
          "preferences" = {
            name = "Preferences";
            exec = "qutebrowser --basedir ${configDir}/qutebrowser/profiles/work qute://settings";
          };
        };
      };
    };
  };

  services = {
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
    CHROME_EXECUTABLE = "${pkgs.ungoogled-chromium}/bin/chromium";
  };
}

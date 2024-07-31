{ config, pkgs, lib, ... }:
let
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
  isArch = builtins.pathExists "/etc/arch-release";
  homeDir = config.home.homeDirectory;
  configDir = config.xdg.configHome;
  themeName = config.theme.name;
  themeVariant = config.theme.variant;
in {
  imports = [ ./theme-setting.nix ];

  home.packages = with pkgs; [
    timewarrior # time tracker
    grc # colorizes CLI output

    ## Devex
    sumneko-lua-language-server
    gopls
    black
    delve
    impl
    gotools
    luajitPackages.jsregexp
    mdformat
    clang-tools
    buf
    buf-language-server
    prettierd
    isort
    actionlint
    mypy
    tree-sitter
    nodejs_22
    ripgrep
    flutter
    android-tools
    statix
    alejandra

    ## CLI
    manix # CLI for nix docs
    neovim # IDE (tExT eDiToR)
    tmux # Terminal multiplexer
    yadm # Dotfile manager
    gh # GitHub CLI
    git # Version control system
    git-lfs # Git extension for large files
    gnupg # GNU Privacy Guard
    pinentry-tty # Enter password in terminal
    gnumake # Build automation tool
    delta # Pretty diffs
    bat # Cat replacement
    gcc # GNU Compiler Collection
    pls # ls replacement
    fd # find replacement
    zoxide # cd replacement
    fzf # Multi-purpose fuzzy finder
    jq # CLI for json manipulation
    python3 # The language python
    nix-prefetch-git # Utility for populating nix fetchgit expressions
    tree # List directory contents
  ];

  programs = {
    kitty = {
      enable = true;
      shellIntegration.enableFishIntegration = true;
      shellIntegration.mode = "no-cursor";
      settings = {
        enable_audio_bell = true;
        window_padding_width = 8;
        allow_remote_control = false;
        repaint_delay = 5;
        input_delay = 1;
        cursor_shape = "blocK";
        macos_option_as_alt = true;
        scrollback_pager = "nvim -c 'set ft=sh' -";
        paste_actions = "quote-urls-at-prompt";
      };
    };
    taskwarrior = {
      enable = true;
      dataLocation = "${config.xdg.dataHome}/task";
      extraConfig = ''
        uda.blocks.type=string
        uda.blocks.label=Blocks
        news.version=2.6.0

        # Put contexts defined with `task context define` in this file
        include ${configDir}/task/context.config
        hooks.location=${configDir}/task/hooks
      '';
    };
    fish = import ./home/fish.nix { inherit config pkgs isArch; };
    qutebrowser = {
      # Uses VCS dotfiles
      enable = true;
      loadAutoconfig = true;
    };
    # Bottom bar
    waybar = lib.mkIf isLinux { enable = true; };
    # Program launcher
    wofi = lib.mkIf isLinux {
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
  };

  home = {
    sessionVariables = {
      EDITOR = "${pkgs.neovim}/bin/nvim";
      MANPAGER = "sh -c 'sed -e s/.\\\\x08//g | bat -l man -p'";
      CONF = configDir;
      CODE = "${homeDir}/Code";
      # Shell prompts tend to manage venvs themselves
      VIRTUAL_ENV_DISABLE_PROMPT = 1;
      BAT_THEME =
        if themeName == "gruvbox" then "gruvbox-${themeVariant}" else "base16";
    } // (if isLinux then {
      OS = "Linux";
      ANDROID_SDK_ROOT = "${homeDir}/Android/Sdk";
      ANDROID_HOME = config.home.sessionVariables.ANDROID_SDK_ROOT;
      CHROME_EXECUTABLE = "${pkgs.ungoogled-chromium}/bin/chromium";
    } else if isDarwin then {
      OS = "Darwin";
      ANDROID_HOME = "/Users/${config.home.username}/Library/Android/sdk";
    } else
      { });

    # Extra stuff to add to $PATH
    sessionPath = if isDarwin then
      [
        # homebrew puts all its stuff in this directory instead
        # of /usr/bin or otherwise
        "/opt/homebrew/bin"
      ]
    else
      [ ];

    preferXdgDirectories = true;
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
  };

  wayland.windowManager.hyprland =
    import ./home/hyprland.nix { inherit config pkgs lib; };

  services = {
    hyprpaper.enable = true;
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

  # Neovim theme
  xdg.configFile."nvim/lua/theme.lua".text = let
    n = config.theme.name;
    func = if n == "gruvbox" then "GruvboxTheme" else "GruvboxTheme";
    fontName = config.stylix.fonts.monospace.name;
    fontSize = config.stylix.fonts.sizes.terminal;
  in ''
    local M = {}

    function M.setup()
      ${func}('${config.theme.variant}')
      if vim.g.neovide then
        vim.o.guifont = "${fontName}:h${toString fontSize}"
      end
    end

    return M
  '';

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = [ "org.qutebrowser.qutebrowser.desktop" ];
      "x-scheme-handler/https" = [ "org.qutebrowser.qutebrowser.desktop" ];
      "text/html" = [ "org.qutebrowser.qutebrowser.desktop" ];
      "application/xhtml+xml" = [ "org.qutebrowser.qutebrowser.desktop" ];
    };
  };

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}

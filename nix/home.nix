{
  config,
  pkgs,
  lib,
  ...
}: let
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
  isArch = builtins.pathExists "/etc/arch-release";
  homeDir = config.home.homeDirectory;
  configDir = config.xdg.configHome;
  themeName = config.theme.name;
  themeVariant = config.theme.variant;
in {
  imports = [
    ./theme.nix
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
    fish = import ./home/fish.nix {inherit config pkgs isArch;};
    qutebrowser = {
      # Uses VCS dotfiles
      enable = true;
      loadAutoconfig = true;
    };
  };

  home = {
    sessionVariables =
      {
        EDITOR = "${pkgs.neovim}/bin/nvim";
        MANPAGER = "sh -c 'sed -e s/.\\\\x08//g | bat -l man -p'";
        CONF = configDir;
        CODE = "${homeDir}/Code";
        # Shell prompts tend to manage venvs themselves
        VIRTUAL_ENV_DISABLE_PROMPT = 1;
        BAT_THEME =
          if themeName == "gruvbox"
          then "gruvbox-${themeVariant}"
          else "base16";
      }
      // (
        if isLinux
        then {
          OS = "Linux";
          ANDROID_SDK_ROOT = "${homeDir}/Android/Sdk";
          ANDROID_HOME = config.home.sessionVariables.ANDROID_SDK_ROOT;
          CHROME_EXECUTABLE = "${pkgs.ungoogled-chromium}/bin/chromium";
        }
        else if isDarwin
        then {
          OS = "Darwin";
          ANDROID_HOME = "/Users/${config.home.username}/Library/Android/sdk";
        }
        else {}
      );

    # Extra stuff to add to $PATH
    sessionPath =
      if isDarwin
      then [
        # homebrew puts all its stuff in this directory instead
        # of /usr/bin or otherwise
        "/opt/homebrew/bin"
      ]
      else [];

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

  wayland.windowManager.hyprland = import ./home/hyprland.nix {inherit config pkgs lib;};

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
  };

  # Neovim theme
  xdg.configFile."nvim/lua/theme.lua".text = let
    n = config.theme.name;
    func =
      if n == "gruvbox"
      then "GruvboxTheme"
      else "GruvboxTheme";
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
      "x-scheme-handler/http" = ["org.qutebrowser.qutebrowser.desktop"];
      "x-scheme-handler/https" = ["org.qutebrowser.qutebrowser.desktop"];
      "text/html" = ["org.qutebrowser.qutebrowser.desktop"];
      "application/xhtml+xml" = ["org.qutebrowser.qutebrowser.desktop"];
    };
  };

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}

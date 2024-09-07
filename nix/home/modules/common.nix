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
  theme = config.theme;
  themeDarkMode =
    if theme.darkMode
    then "dark"
    else "light";
in {
  imports = [
    ../../theme.nix
  ];

  home.packages = with pkgs; [
    timewarrior # time tracker

    ## Devex
    # sumneko-lua-language-server
    # gopls
    # black
    # delve
    # impl
    # gotools
    # luajitPackages.jsregexp
    # mdformat
    # clang-tools
    # buf
    # buf-language-server
    # prettierd
    # isort
    # actionlint
    # mypy
    # tree-sitter
    # nodejs_22
    # ripgrep
    # flutter
    # android-tools
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
          if theme.name == "gruvbox"
          then "gruvbox-${themeDarkMode}"
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

  xdg.enable = true;

  # Neovim theme
  home.file."${configDir}/nvim/lua/theme.lua".text = let
    n = theme.name;
    func =
      if n == "gruvbox"
      then "GruvboxTheme"
      else "GruvboxTheme";
    # fontName = config.stylix.fonts.monospace.name;
    # fontSize = config.stylix.fonts.sizes.terminal;
    fontName = "Monaco";
    fontSize = 11;
  in ''
    local M = {}

    function M.setup()
      ${func}('${themeDarkMode}')
      if vim.g.neovide then
        vim.o.guifont = "${theme.fontCoding.name}:h${toString theme.fontCoding.size}"
      end
    end

    return M
  '';

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}

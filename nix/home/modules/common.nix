{
  config,
  pkgs,
  ...
}: let
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
    ./fish.nix
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

    statix # Nix linter
    alejandra # Nix formatter
    nil # Nix language server
    ripgrep # Fast grep search tool
    nodejs_22 # A bunch of tools (including Copilot) rely on this

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

    ## GUI
    neovide # Neovim GUI
  ];

  programs = {
    kitty =
      {
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
      }
      // (let
        n = theme.name;
        name =
          if n == "gruvbox"
          then "Gruvbox"
          else throw "Unsupported kitty theme: ${n}";
        dark =
          if theme.darkMode
          then "Dark"
          else "Light";
        kittyTheme = "${name} ${dark}";
      in {
        theme = kittyTheme;
        font = {
          name = theme.fontCoding.name;
          size = 10.0;
        };
      });
    taskwarrior = {
      enable = true;
      dataLocation = "${config.xdg.dataHome}/task";
      extraConfig = ''
        uda.blocks.type=string
        uda.blocks.label=Blocks
        uda.ticket.type=string
        uda.ticket.label=Ticket
        news.version=2.6.0

        # Put contexts defined with `task context define` in this file
        include ${configDir}/task/context.config
        hooks.location=${configDir}/task/hooks
      '';
    };
    git = {
      enable = true;
      userEmail = "jeanlucthumm@gmail.com";
      userName = "Jean-Luc Thumm";
      signing = {
        key = "6887D29E72EBFA1A0785A02A6717084E580D97E0";
        signByDefault = true;
      };
      delta = {
        enable = true;
      };
      aliases = {
        de = "diff";
        s = "status";
        stat = "status";
        d = "diff --cached";
        tree = "log --graph --decorate --oneline --all -n 25";
        treel = "log --graph --decorate --oneline --all";
        check = "checkout";
      };
      extraConfig = {
        merge = {
          tool = "meld";
          conflictstyle = "diff3";
        };
        "mergetool \"meld\"" = {
          cmd = ''meld --auto-merge "$LOCAL" "$BASE" "$REMOTE" --output "$MERGED"'';
        };
        credential.helper = "cache";
        safe.directory = "/opt/flutter";
        pull.rebase = true;
        rebase.merges = true;
        init.defaultBranch = "master";
      };
      includes = [
        {
          path = "${configDir}/delta/themes.gitconfig";
        }
      ];
    };
    gh = {
      enable = true;
      gitCredentialHelper = {
        enable = true;
        hosts = [
          "https://github.com"
          "https://gist.github.com"
        ];
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
        if theme.name == "gruvbox"
        then "gruvbox-${themeDarkMode}"
        else "base16";
    };
    preferXdgDirectories = true;
  };

  xdg.enable = true;

  # Neovim theme
  home.file = {
    "${configDir}/nvim/lua/theme.lua".text = let
      n = theme.name;
      func =
        if n == "gruvbox"
        then "GruvboxTheme"
        else throw "Unsupported nvim theme: ${n}";
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
  };

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}

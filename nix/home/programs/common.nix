{
  config,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;
  configDir = config.xdg.configHome;
in {
  imports = [
    ./fish.nix
    ./nushell
  ];

  home.packages = with pkgs; [
    timewarrior # time tracker

    statix # Nix linter
    alejandra # Nix formatter
    nil # Nix language server
    ripgrep # Fast grep search tool
    nodejs_22 # A bunch of tools (including Copilot) rely on this
    sumneko-lua-language-server # Lua language server
    tree-sitter # Syntax parser extensively used by NeoVim

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
    fzf # Multi-purpose fuzzy finder
    jq # CLI for json manipulation
    python3 # The language python
    nix-prefetch-git # Utility for populating nix fetchgit expressions
    tree # List directory contents
    wget # Download files from the web
    entr # Run arbitrary commands when files change
    aichat # AI chatbot for the terminal
    unzip # Unzip files
    dig # DNS lookup utility

    ## GUI
    neovide # Neovim GUI
  ];

  programs = {
    carapace.enable = true;
    starship.enable = true;

    # cd replacement
    zoxide = {
      enable = true;
      enableNushellIntegration = true;
      enableFishIntegration = true;
    };

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
        uda.ticket.type=string
        uda.ticket.label=Ticket
        news.version=2.6.0

        # Put contexts defined with `task context define` in this file
        include ${configDir}/task/context.config
        hooks.location=${configDir}/task/hooks
      '';
      package = pkgs.taskwarrior3;
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
        options = {
          side-by-side = false;
        };
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
    # GitHub CLI
    gh = {
      enable = true;
      # Allows git to defer to gh for authenticating with GitHub repoes
      gitCredentialHelper = {
        enable = true;
        hosts = [
          "https://github.com"
          "https://gist.github.com"
        ];
      };
      settings = {
        git_protocol = "ssh";
        # Run with `gh [alias]`
        aliases = {
          # Wait until PR checks return with success or error
          watch = "pr checks --watch";
        };
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
    };
    preferXdgDirectories = true;
  };

  xdg.enable = true;

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}

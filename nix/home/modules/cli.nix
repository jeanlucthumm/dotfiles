# Basic CLI setup
{
  config,
  pkgs,
  ...
}: let
  configDir = config.xdg.configHome;
in {
  imports = [
    ../programs/nushell
    ../programs/starship.nix
  ];

  home.packages = with pkgs; [
    timewarrior # time tracker
    manix # CLI for nix docs
    neovim # IDE (tExT eDiToR)
    tmux # Terminal multiplexer
    yadm # Dotfile manager
    gh # GitHub CLI
    git # Version control system
    git-lfs # Git extension for large files
    gnumake # Build automation tool
    fzf # Multi-purpose fuzzy finder
    python3 # The language python
    nix-prefetch-git # Utility for populating nix fetchgit expressions
    tree # List directory contents
    wget # Download files from the web
    entr # Run arbitrary commands when files change
    unzip # Unzip files
    dig # DNS lookup utility
    devenv # Development environment manager
    ffmpeg
    usbutils # USB utilities

    # Modern replacements for common tools
    delta # Pretty diffs
    fd # find replacement
    dust # du replacement
    eza # ls replacement
    ripgrep # grep replacement

    # Global dev tools
    alejandra # Nix formatter
    nil # Nix LSP
    nodejs_22 # A bunch of tools (including Copilot) rely on this
    sumneko-lua-language-server # Lua language server
    tree-sitter # Syntax parser extensively used by NeoVim
    mdformat # Markdown formatter
    gcc # GNU Compiler Collection
  ];

  programs = {
    carapace.enable = true;
    bat.enable = true; # Cat replacement
    direnv.enable = true;

    # Modern nix CLI wrapper
    nh = {
      enable = true;
      flake = config.home.homeDirectory + "/nix";
    };

    # cd replacement
    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };

    yazi = {
      enable = true;
      plugins = {
        "rsync" = pkgs.yaziPlugins.rsync;
        "smart-filter" = pkgs.yaziPlugins.smart-filter;
      };
      keymap.mgr.prepend_keymap = [
        {
          on = ["R"];
          run = "plugin rsync";
          desc = "Copy files using rsync";
        }
        {
          on = ["F"];
          run = "plugin smart-filter";
          desc = "Filter files using smart filter";
        }
      ];
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
        head = "symbolic-ref --short HEAD";
        ignore = "!gi() { curl -sL https://www.toptal.com/developers/gitignore/api/$@ ;}; gi";
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
      ignores = [
        ".DS_Store"
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
      # Shell prompts tend to manage venvs themselves
      VIRTUAL_ENV_DISABLE_PROMPT = 1;
    };
    preferXdgDirectories = true;
  };
  xdg.enable = true;
}

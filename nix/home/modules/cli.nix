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
    taskwarrior-enhanced # Enhanced taskwarrior companion CLI
    manix # CLI for nix docs
    neovim # IDE (tExT eDiToR)
    tmux # Terminal multiplexer
    yadm # Dotfile manager
    gh # GitHub CLI
    git # Version control system
    git-lfs # Git extension for large files
    git-filter-repo # Git tool for rewriting history
    git-crypt # Encrypt files in git repos
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
    htop # Interactive process viewer
    jq # Command-line JSON processor
    just # Handy task runner
    notify # Cross-platform notifications

    # Modern replacements for common tools
    delta # Pretty diffs
    fd # find replacement
    dust # du replacement
    eza # ls replacement
    ripgrep # grep replacement
    bat-extras.batman # man replacement
    sd # sed replacement

    # Global dev tools
    alejandra # Nix formatter
    nil # Nix LSP
    # nodejs_22 # A bunch of tools (including Copilot) rely on this
    lua-language-server # Lua language server
    tree-sitter # Syntax parser extensively used by NeoVim
    mdformat # Markdown formatter
    gcc # GNU Compiler Collection
    nix-update # Nix overlay updater
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
          on = ["<C-i>"];
          run = "forward";
          desc = "Go forward to next directory";
        }
        {
          on = ["<C-o>"];
          run = "back";
          desc = "Go back to previous directory";
        }
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
        {
          on = ["c" "y"];
          run = ''shell --block -- ${pkgs.nushell}/bin/nu --login -c "cat \"$1\" | clip"'';
          desc = "Copy file contents to clipboard";
        }
      ];
    };

    git = {
      enable = true;
      signing = {
        key = "6887D29E72EBFA1A0785A02A6717084E580D97E0";
        signByDefault = true;
      };
      includes = [
        {
          path = "${configDir}/delta/themes.gitconfig";
        }
      ];
      ignores = [
        ".DS_Store"
      ];
      settings = {
        user = {
          email = "jeanlucthumm@gmail.com";
          name = "Jean-Luc Thumm";
        };
        alias = {
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
        diff.context = 15;
      };
    };

    delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        side-by-side = false;
      };
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

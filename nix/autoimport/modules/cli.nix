# CLI
fp @ {
  jlib,
  withSystem,
  ...
}: {
  flake.modules.nixos.base = {pkgs, ...}: {
    # Basic system wide packages
    environment.systemPackages = with pkgs; [
      file # Figure out what a certain file is
      lsof # Open files (but good for ports)
      tmux # Terminal multiplexer
      git # Version control
      nushell # Shell so I don't have to use bash for sysadmin
      yadm # Dotfile manager
      vim # Text editor
    ];
  };

  flake.modules.homeManager.base = jlib.mkHomeManager {
    generic = {
      config,
      pkgs,
      ...
    }: let
      clip = pkgs.writeShellScriptBin "clip" ''
        if [ -n "$TMUX" ]; then
          tmux loadb -
        elif [ "$(uname)" = "Darwin" ]; then
          pbcopy
        elif [ "$XDG_SESSION_TYPE" = "wayland" ]; then
          wl-copy
        else
          xclip -selection clipboard
        fi
      '';

      paste = pkgs.writeShellScriptBin "paste" ''
        if [ -n "$TMUX" ]; then
          # No -t/-b flag: plain showb prints the most recent buffer, and the
          # old `-t 0` index form errors out on tmux >= 3.x ("unknown flag -t")
          tmux showb
        elif [ "$(uname)" = "Darwin" ]; then
          pbpaste
        elif [ "$XDG_SESSION_TYPE" = "wayland" ]; then
          wl-paste
        else
          xclip -selection clipboard -o
        fi
      '';
    in {
      # Aliases resolve before PATH lookup, so nix devshells that put
      # coreutils first (e.g. repl-it-web via direnv) can't shadow the
      # clipboard wrappers with POSIX paste, which hangs reading stdin.
      programs.nushell.shellAliases = {
        clip = "^${clip}/bin/clip";
        paste = "^${paste}/bin/paste";
      };

      home.packages = with pkgs; let
        system = pkgs.stdenv.hostPlatform.system;
        fpkgs = withSystem system ({config, ...}: config.packages);
      in [
        fpkgs.review-pr # LSP-enabled nvim review of a jj workspace PR

        # Foundation — bare essentials
        neovim # IDE (tExT eDiToR)
        tmux # Terminal multiplexer
        htop # Interactive process viewer
        python3 # The language python
        wget # Download files from the web
        unzip # Unzip files
        dig # DNS lookup utility
        jq # Command-line JSON processor

        # Modern shell niceties
        fzf # Multi-purpose fuzzy finder
        fd # find replacement
        dust # du replacement
        eza # ls replacement
        ripgrep # grep replacement
        bat-extras.batman # man replacement
        sd # sed replacement

        # Cross-platform clipboard
        clip
        paste

        # Sysadmin
        manix # CLI for nix docs
        yadm # Dotfile manager
        nix-prefetch-git # Utility for populating nix fetchgit expressions
        alejandra # Nix formatter
        nil # Nix LSP
        nix-update # Nix overlay updater
      ];

      programs = {
        carapace.enable = true;
        bat.enable = true; # cat replacement
        direnv = {
          enable = true;
          nix-direnv.enable = true; # caches dev shells so cd is instant
        };
        zoxide.enable = true; # cd replacement

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
          ];
        };

        # Modern nix CLI wrapper
        nh = {
          enable = true;
          flake = config.home.homeDirectory + "/nix";
        };
      };

      home = {
        preferXdgDirectories = true;
        sessionVariables = {
          EDITOR = "${pkgs.neovim}/bin/nvim";
          MANPAGER = "sh -c 'sed -e s/.\\\\x08//g | bat -l man -p'";
        };
      };
      xdg.enable = true;
    };

    nixos = {pkgs, ...}: {
      home.packages = with pkgs; [
        keyutils # Kernel key services
        bitwarden-cli # Bitwarden CLI
      ];
    };
  };
}

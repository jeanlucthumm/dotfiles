# Dev role: what a human at the keyboard needs on top of `agents`. The agents
# role (agents.nix) owns git/jj/gh, build tools and all AI tooling; this adds
# the human-only extras (mergetools, delta, aliases, LSPs, taskwarrior).
# Always imported together with agents, never alone.
fp @ {
  jlib,
  withSystem,
  ...
}: {
  flake.modules.nixos.dev = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      # Docker Compose alternative for Podman
      podman-compose
      # Android Debug Bridge (ADB) for Android development
      android-tools
    ];

    home-manager.sharedModules = [fp.config.flake.modules.homeManager.dev];
  };

  flake.modules.darwin.dev = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      qemu
    ];

    home-manager.sharedModules = [fp.config.flake.modules.homeManager.dev];
  };

  flake.modules.homeManager.dev = jlib.mkHomeManager {
    generic = {
      config,
      pkgs,
      ...
    }: let
      configDir = config.xdg.configHome;
      system = pkgs.stdenv.hostPlatform.system;
      taskwarrior-enhanced = fp.inputs.taskwarrior-enhanced.packages.${system}.taskwarrior-enhanced;
      fpkgs = withSystem system ({config, ...}: config.packages);
    in {
      home.packages = with pkgs; [
        # Core dev tools
        git-filter-repo # Git tool for rewriting history
        git-crypt # Encrypt files in git repos
        lua-language-server # Lua language server
        tree-sitter # Syntax parser extensively used by NeoVim
        mdformat # Markdown formatter
        flarectl # Cloudflare CLI (zones, DNS, WAF)
        fpkgs.hex-cli # Hex (hex.tech) notebook CLI: author/run projects from the terminal
        fpkgs.bt # Braintrust CLI: query traces/logs with BTQL (bt sql / view / sync pull)

        # Workflow-specific
        timewarrior # time tracker
        taskwarrior-enhanced # Enhanced taskwarrior companion CLI (from input flake)
      ];

      programs = {
        git = {
          # Identity and signing come from agents.nix; the YubiKey signing key
          # from the secrets role.
          includes = [
            {
              path = "${configDir}/delta/themes.gitconfig";
            }
          ];
          ignores = [
            ".DS_Store"
          ];
          settings = {
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
            rebase.merges = true;
            diff.context = 15;
          };
        };

        delta = {
          enable = true;
          enableGitIntegration = true;
          enableJujutsuIntegration = true;
          options = {
            side-by-side = false;
          };
        };

        gh = {
          # Allows git to defer to gh for authenticating with GitHub repos
          gitCredentialHelper = {
            enable = true;
            hosts = [
              "https://github.com"
              "https://gist.github.com"
            ];
          };
          settings = {
            # Run with `gh [alias]`
            aliases = {
              # Wait until PR checks return with success or error
              watch = "pr checks --watch";
            };
          };
        };
      };
    };

    darwin = {
      pkgs,
      system,
      ...
    }: {
      home.packages = let
        tb = fp.inputs.terminal-browser.packages.${system}.default;
      in [
        # Wrapped so every caller (nushell, agents, scripts) gets the palette
        # off cmd+p, which kitty owns. The flag must trail the args, and
        # `action` rejects unknown flags, so only browser launches get it.
        (pkgs.writeShellScriptBin "terminal-browser" ''
          case "$1" in
            action | ls | setup | help)
              exec ${tb}/bin/terminal-browser "$@"
              ;;
            *)
              exec ${tb}/bin/terminal-browser "$@" --palette-key=ctrl+p
              ;;
          esac
        '')
      ];
    };
  };
}

# Agents role: everything a coding agent needs to work in a repo, whether a
# human is driving it live or it runs in the background (e.g. `claude rc` on
# server). `dev` is the human layer on top (mergetools, delta, aliases, LSPs,
# taskwarrior), so dev hosts import both and agent-only hosts just this.
#
# claude-code.nix and agent-memory.nix contribute to homeManager.agents too.
#
# Commits are authored as Jean-Luc. Signing defaults to a host-local SSH key
# (no hardware touch possible on a headless box); hardware-key hosts override
# the key via the secrets role. A host-local key must be registered on GitHub
# as a *signing* key or commits show Unverified.
fp @ {
  jlib,
  withSystem,
  ...
}: {
  flake.modules.nixos.agents = {
    home-manager.sharedModules = [fp.config.flake.modules.homeManager.agents];
  };

  flake.modules.darwin.agents = {
    home-manager.sharedModules = [fp.config.flake.modules.homeManager.agents];
  };

  flake.modules.homeManager.agents = jlib.mkHomeManager {
    generic = {
      config,
      lib,
      pkgs,
      ...
    }: let
      identity = {
        email = "jeanlucthumm@gmail.com";
        name = "Jean-Luc Thumm";
      };
    in {
      # git, git-lfs, gh and jj come from their programs.* below.
      home.packages = with pkgs; [
        devenv # per-project dev environments; loaded into sessions by claude-devenv-env
        just
        gnumake
        gcc
        entr

        # `pnpm dlx` for npm-published MCP servers (e.g. firefox-devtools-mcp).
        # nodejs is needed alongside it: the servers' bin scripts shebang on
        # `env node`, and nixpkgs' pnpm keeps its own node private.
        nodejs
        pnpm
      ];

      programs = {
        git = {
          enable = true;
          lfs.enable = true;
          signing = {
            format = "ssh";
            key = lib.mkDefault "~/.ssh/id_ed25519_signing";
            signByDefault = true;
          };
          settings = {
            user = identity;
            pull.rebase = true;
            init.defaultBranch = "master";
          };
        };

        jujutsu = {
          enable = true;
          settings = lib.mkMerge [
            {user = identity;}
            # Follow git: hosts that turn git signing off (e.g. desktop) get
            # unsigned jj too. Sign at push time rather than on every rewrite:
            # jj rewrites commits constantly, and a hardware key would need a
            # touch each time.
            (lib.mkIf config.programs.git.signing.signByDefault {
              signing = {
                backend = "ssh";
                inherit (config.programs.git.signing) key;
              };
              git.sign-on-push = true;
            })
          ];
        };

        # Push/pull go over SSH. gh itself is logged in by hand for now.
        gh = {
          enable = true;
          settings.git_protocol = "ssh";
        };
      };
    };

    nixos = {system, ...}: let
      fpkgs = withSystem system ({config, ...}: config.packages);
    in {
      home.packages = [
        fpkgs.reddit-mcp-server
      ];

      programs.codex.enable = true;
    };
  };
}

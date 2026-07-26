# Auto-sync of the agents' memory repo (~/memory).
#
# Agents (Claude Code etc.) write markdown memory into a git repo; git-sync
# turns that into a browsable timeline. Every `interval` seconds a sync pass
# commits whatever is dirty ("changes from <host> on <date>") and pushes,
# pulling/rebasing changes from other hosts first. Clean tree = no commit.
# A rebase conflict halts syncing and leaves the repo mid-rebase for manual
# resolution. (The upstream module also syncs on repo changes via launchd
# WatchPaths; that's forced off below so the cadence is purely interval-based.)
{
  flake.modules.homeManager.dev = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.jl.agentMemory;
    remote = "git@github.com:jeanlucthumm/agent-memory.git";
  in {
    options.jl.agentMemory = {
      enable = lib.mkEnableOption "agent memory repo auto-sync";

      path = lib.mkOption {
        type = lib.types.str;
        default = "${config.home.homeDirectory}/memory";
        description = "Location of the agent memory git repo";
      };

      interval = lib.mkOption {
        type = lib.types.int;
        default = 43200;
        description = ''
          Seconds between sync passes. A pass only commits if the repo is
          dirty, so this caps commit frequency (default ~2/day). Coarser
          intervals mean a bigger window for cross-host rebase conflicts.
        '';
      };
    };

    config = lib.mkIf cfg.enable (lib.mkMerge [
      {
        services.git-sync = {
          enable = true;
          repositories.agent-memory = {
            path = cfg.path;
            uri = remote;
            inherit (cfg) interval;
          };
        };

        # One-time repo prep git-sync insists on: the branch must be opted in,
        # and untracked files are only committed with syncNewFiles. Clone here
        # too since the home-manager module only auto-clones on Linux.
        home.activation.agentMemorySetup = lib.hm.dag.entryAfter ["writeBoundary"] ''
          if [ ! -e "${cfg.path}/.git" ]; then
            run ${pkgs.git}/bin/git clone ${remote} "${cfg.path}" \
              || verboseEcho "agent-memory: clone failed (offline?); git-sync is inert until ${cfg.path} exists"
          fi
          if [ -e "${cfg.path}/.git" ]; then
            run ${pkgs.git}/bin/git -C "${cfg.path}" config --bool branch.main.sync true
            run ${pkgs.git}/bin/git -C "${cfg.path}" config --bool git-sync.syncNewFiles true
          fi
        '';
      }
      (lib.mkIf pkgs.stdenv.isDarwin {
        # Sync on the interval only — without this, launchd also fires a
        # sync every time the repo top level changes.
        launchd.agents.git-sync-agent-memory.config.WatchPaths = lib.mkForce [];
      })
    ]);
  };
}

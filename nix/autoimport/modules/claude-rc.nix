# Always-on `claude rc` (Remote Control) servers, one systemd user unit per
# project directory, so sessions can be driven from claude.ai/code and the
# phone app across reboots. Needs linger for the user so units start at boot.
#
# Flags per unit:
#   --spawn <mode>                per dir. `worktree`: each new session gets
#                                 its own git worktree (dir must be a git
#                                 repo). `same-dir`: sessions work in the dir
#                                 itself -- for trees where edits must land
#                                 in place, e.g. the Syncthing-shared vault;
#   --no-create-session-in-dir    otherwise every restart leaves an empty
#                                 session behind in the app;
#   --permission-mode auto        classifier-gated; degrades to prompts rather
#                                 than wedging, unlike skip-permissions.
# On restart rc reconnects the sessions it had; no --continue needed.
#
# rc takes no --add-dir/--mcp-config/--settings, so everything that scopes a
# session (instructions, MCP servers, extra readable dirs) comes from the
# directory itself: its CLAUDE.md chain, .claude/settings.json and .mcp.json.
# Pointing a unit at a subdirectory is therefore how an agent gets a scope.
#
# Workspace trust is the one interactive gate: on an untrusted dir rc exits
# with "Workspace not trusted". ExecStartPre seeds it in ~/.claude.json,
# keyed the way Claude Code keys it: the git toplevel when the dir is inside
# a repo, else the dir itself. Trust also gates the dir's .claude/settings.json
# (project allow rules, additionalDirectories), which is otherwise silently
# ignored. Live claude processes rewrite that file too, so the seed only
# writes when the flag is missing, via temp file + atomic mv to keep the race
# window small.
_: {
  flake.modules.homeManager.agents = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.jl.claude.rc;
    jq = "${pkgs.jq}/bin/jq";

    seedTrust = dir:
      pkgs.writeShellScript "claude-rc-seed-trust" ''
        set -euo pipefail
        f="$HOME/.claude.json"
        [ -s "$f" ] || echo '{}' >"$f"
        key=$(${pkgs.git}/bin/git -C ${lib.escapeShellArg dir} rev-parse --show-toplevel 2>/dev/null \
          || echo ${lib.escapeShellArg dir})
        if ! ${jq} -e --arg d "$key" \
          '.projects[$d].hasTrustDialogAccepted == true' "$f" >/dev/null; then
          tmp=$(mktemp "$f.XXXXXX")
          ${jq} --arg d "$key" \
            '.projects[$d].hasTrustDialogAccepted = true' "$f" >"$tmp"
          mv "$tmp" "$f"
        fi
      '';

    mkUnit = name: {
      dir,
      spawn,
    }: {
      name = "claude-rc-${name}";
      value = {
        Unit = {
          Description = "Claude Code remote control: ${name} (${dir})";
          # Don't restart on switch: the unit's cgroup holds every session it
          # spawned, including one that may be running the switch itself. A
          # new claude takes effect on the next manual restart or reboot.
          X-SwitchMethod = "keep-old";
        };
        Service = {
          WorkingDirectory = dir;
          ExecStartPre = "${seedTrust dir}";
          ExecStart = lib.escapeShellArgs [
            "${config.jl.claude.package}/bin/claude"
            "rc"
            "--permission-mode"
            "auto"
            "--spawn"
            spawn
            "--no-create-session-in-dir"
            "--name"
            name
          ];
          Restart = "always";
          RestartSec = 10;
          # The TUI redraws constantly with no terminal attached.
          StandardOutput = "null";
        };
        Install.WantedBy = ["default.target"];
      };
    };
    rcDir = lib.types.submodule {
      options = {
        dir = lib.mkOption {
          type = lib.types.strMatching "/.*";
          description = "Absolute directory the sessions start in.";
        };
        spawn = lib.mkOption {
          type = lib.types.enum ["worktree" "same-dir"];
          default = "worktree";
          description = ''
            `worktree`: each session gets its own git worktree (dir must be
            a git repo). `same-dir`: sessions share the directory itself, so
            edits land in place -- for non-repos and Syncthing-shared trees.
          '';
        };
      };
    };
  in {
    options.jl.claude.rc.dirs = lib.mkOption {
      type = lib.types.attrsOf rcDir;
      default = {};
      example = {
        dotfiles.dir = "/home/jeanluc/dotfiles";
        chore = {
          dir = "/home/jeanluc/obsidian/vault/chore";
          spawn = "same-dir";
        };
      };
      description = ''
        `claude rc` servers to run, keyed by session name. Each becomes the
        user unit claude-rc-<name>.
      '';
    };

    config.systemd.user.services = lib.mapAttrs' mkUnit cfg.dirs;
  };
}

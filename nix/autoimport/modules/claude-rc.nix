# Always-on `claude rc` (Remote Control) servers, one systemd user unit per
# project directory, so sessions can be driven from claude.ai/code and the
# phone app across reboots. Needs linger for the user so units start at boot.
#
# Flags per unit:
#   --spawn worktree              each new session gets its own git worktree
#                                 (so dirs must be git repos);
#   --no-create-session-in-dir    otherwise every restart leaves an empty
#                                 session behind in the app;
#   --permission-mode auto        classifier-gated; degrades to prompts rather
#                                 than wedging, unlike skip-permissions.
# On restart rc reconnects the sessions it had; no --continue needed.
#
# Workspace trust is the one interactive gate: on an untrusted dir rc exits
# with "Workspace not trusted". ExecStartPre seeds it in ~/.claude.json. Live
# claude processes rewrite that file too, so the seed only writes when the
# flag is missing, via temp file + atomic mv to keep the race window small.
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
        if ! ${jq} -e --arg d ${lib.escapeShellArg dir} \
          '.projects[$d].hasTrustDialogAccepted == true' "$f" >/dev/null; then
          tmp=$(mktemp "$f.XXXXXX")
          ${jq} --arg d ${lib.escapeShellArg dir} \
            '.projects[$d].hasTrustDialogAccepted = true' "$f" >"$tmp"
          mv "$tmp" "$f"
        fi
      '';

    mkUnit = name: dir: {
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
            "worktree"
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
  in {
    options.jl.claude.rc.dirs = lib.mkOption {
      type = lib.types.attrsOf (lib.types.strMatching "/.*");
      default = {};
      example = {dotfiles = "/home/jeanluc/dotfiles";};
      description = ''
        `claude rc` servers to run, as session name -> absolute directory
        (a git repo). Each becomes the user unit claude-rc-<name>.
      '';
    };

    config.systemd.user.services = lib.mapAttrs' mkUnit cfg.dirs;
  };
}

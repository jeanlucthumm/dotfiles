# Claude Code as an always-on Telegram agent on the server.
#
# Supersedes the Hermes gateway (removed; see git history). Same premise --
# text a bot, an agent does the work -- but the agent is Claude Code itself, so
# it gets the real harness (skills, MCP, subagents, connectors) and runs on the
# claude.ai subscription rather than metered API credits.
#
# Shape: a systemd unit holds a detached tmux session running an *interactive*
# Claude Code TUI with the Telegram channel plugin attached. Interactive rather
# than `-p` on purpose -- channel events cannot carry slash commands, so
# attaching is the only way to reach /compact, /clear, /login and /mcp:
#
#   sudo -u claude-agent tmux -L claude attach      # Ctrl-b d to detach
#
# systemd here is a lifecycle shim, not a supervisor. Type=oneshot +
# RemainAfterExit only guarantees the session exists after boot. It deliberately
# does NOT restart claude on crash: tmux double-forks its server, so systemd
# cannot see the real process and a Restart= policy would silently never fire.
# Better no supervision than fake supervision. `systemctl restart claude-agent`
# tears the session down and rebuilds it, which doubles as the context reset --
# the only way to clear a session the channel can't send slash commands to.
fp: {
  flake.modules.nixos.homeServer = {pkgs, ...}: let
    user = "claude-agent";
    home = "/var/lib/${user}";

    # The agent's cwd. Kept distinct from $HOME so the session doesn't treat
    # ~/.claude as its project directory.
    workspace = "${home}/workspace";

    # Telegram plugin state: access.json (the allowlist), its bot.pid lock and
    # inbox/. This is the plugin's own default location, left alone on purpose
    # so the upstream docs' paths match what is actually on disk.
    stateDir = "${home}/.claude/channels/telegram";

    # Deposited by `deposit-secrets` (see secrets/secrets.nix). Env-file format.
    # The plugin reads TELEGRAM_BOT_TOKEN from the real environment, which wins
    # over the .env file it would otherwise look for in stateDir.
    envFile = "${home}/telegram.env";

    # Named socket, so `tmux -L claude attach` finds the session regardless of
    # what else the user is running.
    tmuxCmd = "${pkgs.tmux}/bin/tmux -L claude";

    claudePkg = fp.inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;

    # Everything the agent can reach. Nix is the only way it gains capabilities
    # -- there is no self-install loop, which is the price of a read-only store
    # and the point of a declarative box.
    agentPath = with pkgs; [
      claudePkg
      bun # channel plugins are Bun scripts
      tmux
      git
      jq
      ripgrep
      fd
      curl
      coreutils
      gnused
      gnugrep
      findutils
      nodejs
      openssh
      bashInteractive
    ];

    marketplace = "claude-plugins-official";
    plugin = "telegram@${marketplace}";

    # User-level settings, and the whole of them: nix rewrites this file on every
    # restart, so anything Claude Code persists here is lost. That is why the
    # plugin is *declared* rather than installed -- `claude plugin install`
    # writes these same two keys, and the next restart would silently drop them,
    # leaving an on-disk plugin that no longer loads.
    #
    # `auto` is only honoured from *user* settings -- Claude Code ignores
    # defaultMode: "auto" in project/local files so a repo cannot grant itself
    # the mode.
    settingsJson = pkgs.writeText "claude-agent-settings.json" (builtins.toJSON {
      # HTTPS, not the `anthropics/${marketplace}` shorthand: that resolves to
      # git@github.com and this box has no GitHub SSH key (and no outbound :22).
      extraKnownMarketplaces.${marketplace}.source = {
        source = "git";
        url = "https://github.com/anthropics/${marketplace}.git";
      };
      enabledPlugins.${plugin} = true;

      permissions = {
        # Classifier-backed: actions run without prompting, but a background
        # model blocks escalation, exfiltration and prompt-injection-shaped
        # calls. Strictly better than bypassPermissions for a box reachable
        # from the internet by anyone who can message the bot.
        #
        # If the classifier blocks 3 times consecutively (or 20 times total)
        # auto mode pauses and starts prompting again; those prompts relay to
        # Telegram as inline buttons, so it degrades rather than wedges.
        defaultMode = "auto";
      };
    });

    claudeMd = pkgs.writeText "claude-agent-CLAUDE.md" ''
      # Operating context

      You are running as an always-on agent on `server`, a headless NixOS home
      server, reachable over Telegram. Messages arrive as `<channel>` events and
      you reply through the telegram reply tool.

      - You are talking to Jean-Luc. Answers are read on a phone: be terse, lead
        with the answer, skip preamble.
      - Your working directory is `${workspace}`. Treat it as scratch space.
      - You cannot install system packages -- this machine is declarative NixOS
        and the store is read-only. If you need a tool that isn't present, say
        so and name it rather than trying to install it.
      - Slash commands do not work over Telegram; they are a terminal-only
        construct. If the session needs /compact or /clear, say so and Jean-Luc
        will attach over SSH.
    '';

    # Runs before the session starts, as the service user.
    bootstrap = pkgs.writeShellScript "claude-agent-bootstrap" ''
      set -euo pipefail
      umask 077

      # Also creates ~/.claude, being a parent. The workspace comes from
      # StateDirectory.
      mkdir -p ${stateDir}

      # Static access mode: the plugin snapshots access.json at boot and never
      # re-reads or writes it, so the pairing dance is unnecessary and the
      # allowlist is fully declarative. dmPolicy "pairing" would be downgraded
      # to "allowlist" anyway, so state it directly. TELEGRAM_ALLOWED_USERS is a
      # comma-separated list of numeric Telegram user IDs, and lives in the same
      # deposited env file as the bot token.
      #
      # Missing is a warning, not a hard failure: this host is deployed with
      # deploy-rs, where a unit that fails to start aborts activation and rolls
      # the entire deployment back -- a missing secret must not be able to veto
      # unrelated server config. The session still comes up so you can attach,
      # and the plugin itself exits loudly if the bot token is also absent.
      if [ -z "''${TELEGRAM_ALLOWED_USERS:-}" ]; then
        echo "claude-agent: WARNING -- TELEGRAM_ALLOWED_USERS is unset in ${envFile}." >&2
        echo "  Leaving access.json untouched; the bot drops every inbound" >&2
        echo "  message until this is set. Fix with 'deposit-secrets" >&2
        echo "  claude-telegram', then: systemctl restart claude-agent" >&2
      else
        ${pkgs.jq}/bin/jq -n --arg ids "$TELEGRAM_ALLOWED_USERS" '{
          dmPolicy: "allowlist",
          allowFrom: ($ids | split(",") | map(gsub("[[:space:]]"; "")) | map(select(length > 0))),
          groups: {},
          pending: {}
        }' > ${stateDir}/access.json
      fi

      # Copied, not symlinked: the agent must be able to write its own state
      # into ~/.claude, but nix reasserts these two files on every restart.
      install -m 600 ${settingsJson} ${home}/.claude/settings.json
      install -m 600 ${claudeMd} ${home}/.claude/CLAUDE.md

      # Clones the marketplace declared above on first boot, and refreshes it
      # afterwards -- the plugin cache lives outside the store, so without this
      # a declared-but-uncloned marketplace fails to load with "cache-miss".
      # Non-fatal: a transient network failure must not veto activation.
      claude plugin marketplace update ${marketplace} || true
    '';

    # The command tmux runs. On exit it drops to a shell rather than letting the
    # pane die, so a crash leaves something to attach to -- the TUI's output
    # never reaches the journal, so a collapsed session would be a silent loss.
    # It also gives you a shell as the service user for the one-time
    # `claude auth login` before the agent can start at all.
    runAgent = pkgs.writeShellScript "claude-agent-run" ''
      cd ${workspace}
      ${claudePkg}/bin/claude \
        --channels plugin:${plugin} \
        --permission-mode auto || true
      echo
      echo "claude exited. Session kept for inspection."
      echo "  re-auth:  claude auth login"
      echo "  restart:  sudo systemctl restart claude-agent"
      exec ${pkgs.bashInteractive}/bin/bash -i
    '';
  in {
    # `path` below only reaches the unit, so without this `claude` exists for
    # the service and nowhere else -- including `sudo -u claude-agent claude
    # auth login`, which is how the agent gets its credential in the first
    # place. Chicken-and-egg, so put it on the system PATH.
    environment.systemPackages = [claudePkg];

    users.groups.${user} = {};
    users.users.${user} = {
      isSystemUser = true;
      group = user;
      inherit home;
      createHome = true;
      # Needed for `sudo -u claude-agent ...` bootstrap over SSH.
      shell = pkgs.bashInteractive;
      description = "Claude Code Telegram agent";
    };

    systemd.services.claude-agent = {
      description = "Claude Code Telegram agent (tmux session)";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
      path = agentPath;

      environment = {
        HOME = home;
        TERM = "xterm-256color";
        # Deliberately no ANTHROPIC_API_KEY: it outranks the subscription
        # credential in ~/.claude/.credentials.json, so its presence would
        # silently bill API credits *and* drop the claude.ai connectors.
      };

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = user;
        Group = user;

        # systemd creates and chowns these under /var/lib before any Exec* runs,
        # which tmpfiles cannot guarantee: activation applies new tmpfiles rules
        # via systemd-tmpfiles-resetup.service, and ordering against it is not
        # something this unit can rely on. Everything deeper (.claude and the
        # channel state dir) is created by the bootstrap, which can, because the
        # home is owned by the service user by then.
        StateDirectory = [user "${user}/workspace"];
        StateDirectoryMode = "0700";

        # $HOME, not the workspace: systemd chdir's here before ExecStartPre
        # runs, so it must already exist. runAgent cd's into the workspace.
        WorkingDirectory = home;

        # Optional so a missing deposit surfaces as the bootstrap's explicit
        # error rather than an opaque systemd failure.
        EnvironmentFile = "-${envFile}";

        ExecStartPre = "${bootstrap}";
        # -A: attach-or-create, so ExecStart is idempotent if a session somehow
        # outlives systemd's view of the unit.
        ExecStart = "${tmuxCmd} new-session -d -A -s main ${runAgent}";
        # Leading '-': kill-server exits non-zero when no session exists, which
        # would otherwise make `stop` report failure.
        ExecStop = "-${tmuxCmd} kill-server";

        # tmux's socket lives under /tmp/tmux-<uid>/. A private /tmp namespace
        # would hide it from `sudo -u claude-agent tmux attach` over SSH, which
        # is the entire operational interface.
        PrivateTmp = false;
      };
    };
  };
}

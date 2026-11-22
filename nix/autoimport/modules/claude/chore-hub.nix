# Chore hub: Telegram agent that dispatches chores, same shape as claude-agent.nix.
# Instructions: vault chore/hub/CLAUDE.md. Attach: tmux -L chore-hub attach
_: {
  flake.modules.nixos.homeServer = {config, ...}: let
    # TELEGRAM_BOT_TOKEN, TELEGRAM_ALLOWED_USERS.
    envFile = config.age.secrets.chore-telegram.path;
  in {
    age.secrets.chore-telegram = {
      file = ../secrets/_age/chore-telegram.age;
      owner = "jeanluc";
    };

    home-manager.users.jeanluc = {
      config,
      pkgs,
      ...
    }: let
      vault = "/home/jeanluc/obsidian/vault";
      # Hub only: --continue resumes this dir's newest conversation.
      dir = "${vault}/chore/hub";
      stateDir = "${config.xdg.stateHome}/chore-hub/telegram";
      tmuxCmd = "${pkgs.tmux}/bin/tmux -L chore-hub";
      claude = "${config.jl.claude.package}/bin/claude";

      marketplace = "claude-plugins-official";
      plugin = "telegram@${marketplace}";
      settings = pkgs.writeText "chore-hub-settings.json" (builtins.toJSON {
        enabledPlugins.${plugin} = true;
        permissions.additionalDirectories = [vault "/home/jeanluc/dotfiles"];
      });

      # Channel plugins run on Bun.
      path = "export PATH=${pkgs.bun}/bin:$PATH";

      # Must not fail: a failed user unit fails the activation, and the deploy.
      bootstrap = pkgs.writeShellScript "chore-hub-bootstrap" ''
        set -uo pipefail
        umask 077
        ${path}
        mkdir -p ${stateDir}

        # Static allowlist, read once at boot.
        if [ -z "''${TELEGRAM_ALLOWED_USERS:-}" ]; then
          echo "chore-hub: TELEGRAM_ALLOWED_USERS is unset in ${envFile};" >&2
          echo "  the bot drops every inbound message until it is set." >&2
        else
          ${pkgs.jq}/bin/jq -n --arg ids "$TELEGRAM_ALLOWED_USERS" '{
            dmPolicy: "allowlist",
            allowFrom: ($ids | split(",") | map(gsub("[[:space:]]"; "")) | map(select(length > 0))),
            groups: {},
            pending: {}
          }' > ${stateDir}/access.json
        fi

        # A marketplace clone older than the plugin doesn't list it.
        ${claude} plugin marketplace update ${marketplace} || true
      '';

      # Ends in a shell so there's always something to attach to.
      runHub = pkgs.writeShellScript "chore-hub-run" ''
        ${path}
        if cd ${dir}; then
          ${claude} \
            --continue \
            --remote-control chore-hub \
            --channels plugin:${plugin} \
            --permission-mode auto \
            --settings ${settings} || true
          echo
          echo "claude exited. Session kept for inspection."
          echo "  re-auth:  claude auth login"
          echo "  restart:  systemctl --user restart claude-chore-hub"
        fi
        exec ${pkgs.bashInteractive}/bin/bash -i
      '';
    in {
      # Hub-spawned sessions can't answer prompts. The store path is what
      # claude-jj-git-rewrite turns `jj git push -b X` into in workspaces.
      jl.claude.settings.permissions.allow = [
        "Bash(jj git push -b *)"
        "Bash(jj git push --bookmark *)"
        "Bash(/nix/store/*-jj-push/bin/jj-push *)"
        "Bash(gh pr create --draft:*)"
        "Bash(gh pr create * --draft*)"
        "Bash(claude-worktree-remove:*)"
      ];

      systemd.user.services.claude-chore-hub = {
        Unit.Description = "Claude Code chore hub (tmux session)";
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          Environment = [
            "TERM=xterm-256color"
            "TELEGRAM_STATE_DIR=${stateDir}"
          ];
          EnvironmentFile = "-${envFile}";
          ExecStartPre = "${bootstrap}";
          ExecStart = "${tmuxCmd} new-session -d -A -s main ${runHub}";
          ExecStop = "-${tmuxCmd} kill-server";
        };
        Install.WantedBy = ["default.target"];
      };
    };
  };
}

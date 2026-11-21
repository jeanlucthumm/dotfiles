# Chore hub: a Telegram agent that dispatches chores, as jeanluc in the vault.
# Same tmux-in-a-oneshot shape as claude-agent.nix; instructions are the
# vault's chore/hub/CLAUDE.md. Attach: tmux -L chore-hub attach
_: {
  flake.modules.nixos.homeServer = {config, ...}: let
    # Env file: TELEGRAM_BOT_TOKEN and TELEGRAM_ALLOWED_USERS.
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
      # Nothing else may run Claude Code here: --continue resumes whichever
      # conversation in this directory is newest.
      dir = "${vault}/chore/hub";
      stateDir = "${config.xdg.stateHome}/chore-hub/telegram";
      tmuxCmd = "${pkgs.tmux}/bin/tmux -L chore-hub";
      claude = "${config.jl.claude.package}/bin/claude";

      marketplace = "claude-plugins-official";
      plugin = "telegram@${marketplace}";
      settings = pkgs.writeText "chore-hub-settings.json" (builtins.toJSON {
        enabledPlugins.${plugin} = true;
      });

      # Channel plugins are Bun scripts, and nothing else of jeanluc's needs
      # bun on PATH.
      path = "export PATH=${pkgs.bun}/bin:$PATH";

      # Nothing here may fail the unit: a user unit that does not start fails
      # the Home Manager activation, and with it the deploy.
      bootstrap = pkgs.writeShellScript "chore-hub-bootstrap" ''
        set -uo pipefail
        umask 077
        ${path}
        mkdir -p ${stateDir}

        # A static allowlist the plugin reads once at boot; see claude-agent.nix.
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

        # The plugin is cached from this clone on first use, and a clone that
        # predates the plugin does not list it.
        ${claude} plugin marketplace update ${marketplace} || true
      '';

      # Ends in a shell either way, so there is always something to attach to.
      runHub = pkgs.writeShellScript "chore-hub-run" ''
        ${path}
        if cd ${dir}; then
          ${claude} \
            --continue \
            --remote-control chore-hub \
            --channels plugin:${plugin} \
            --permission-mode auto \
            --add-dir ${vault} \
            --settings ${settings} || true
          echo
          echo "claude exited. Session kept for inspection."
          echo "  re-auth:  claude auth login"
          echo "  restart:  systemctl --user restart claude-chore-hub"
        fi
        exec ${pkgs.bashInteractive}/bin/bash -i
      '';
    in {
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

# Telegram hubs: agents Jean-Luc messages from his phone, each running as
# jeanluc in its own vault folder, whose CLAUDE.md holds its instructions.
# Same tmux-in-a-oneshot shape as claude-agent.nix.
# Attach: tmux -L <name>-hub attach
{lib, ...}: let
  vault = "/home/jeanluc/obsidian/vault";

  # Nothing else may run Claude Code in a hub's dir: --continue resumes
  # whichever conversation in that directory is newest.
  hubs = {
    # Dispatches chores. Its vault access is a grant made by hand in the
    # vault's .claude/settings.local.json; declaring it here would change the
    # unit and restart the live hub.
    chore = {
      dir = "${vault}/chore/hub";
      addDirs = [];
    };
    # Improves the system itself, mostly through dotfiles sessions.
    system = {
      dir = "${vault}/chore/system-hub";
      addDirs = [vault "/home/jeanluc/dotfiles"];
    };
  };
in {
  flake.modules.nixos.homeServer = {config, ...}: let
    # Env file: TELEGRAM_BOT_TOKEN and TELEGRAM_ALLOWED_USERS.
    envFileOf = name: config.age.secrets."${name}-telegram".path;
  in {
    age.secrets = lib.mapAttrs' (name: _:
      lib.nameValuePair "${name}-telegram" {
        file = ../secrets/_age + "/${name}-telegram.age";
        owner = "jeanluc";
      })
    hubs;

    home-manager.users.jeanluc = {
      config,
      pkgs,
      ...
    }: let
      claude = "${config.jl.claude.package}/bin/claude";
      marketplace = "claude-plugins-official";
      plugin = "telegram@${marketplace}";

      # Channel plugins are Bun scripts, and nothing else of jeanluc's needs
      # bun on PATH.
      path = "export PATH=${pkgs.bun}/bin:$PATH";

      mkHub = name: {
        dir,
        addDirs,
      }: let
        hub = "${name}-hub";
        envFile = envFileOf name;
        stateDir = "${config.xdg.stateHome}/${hub}/telegram";
        tmuxCmd = "${pkgs.tmux}/bin/tmux -L ${hub}";

        settings = pkgs.writeText "${hub}-settings.json" (builtins.toJSON ({
            enabledPlugins.${plugin} = true;
          }
          // lib.optionalAttrs (addDirs != []) {
            permissions.additionalDirectories = addDirs;
          }));

        # Nothing here may fail the unit: a user unit that does not start fails
        # the Home Manager activation, and with it the deploy.
        bootstrap = pkgs.writeShellScript "${hub}-bootstrap" ''
          set -uo pipefail
          umask 077
          ${path}
          mkdir -p ${stateDir}

          # A static allowlist the plugin reads once at boot; see claude-agent.nix.
          if [ -z "''${TELEGRAM_ALLOWED_USERS:-}" ]; then
            echo "${hub}: TELEGRAM_ALLOWED_USERS is unset in ${envFile};" >&2
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
        runHub = pkgs.writeShellScript "${hub}-run" ''
          ${path}
          if cd ${dir}; then
            ${claude} \
              --continue \
              --remote-control ${hub} \
              --channels plugin:${plugin} \
              --permission-mode auto \
              --settings ${settings} || true
            echo
            echo "claude exited. Session kept for inspection."
            echo "  re-auth:  claude auth login"
            echo "  restart:  systemctl --user restart claude-${hub}"
          fi
          exec ${pkgs.bashInteractive}/bin/bash -i
        '';
      in {
        Unit.Description = "Claude Code ${name} hub (tmux session)";
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
    in {
      systemd.user.services =
        lib.mapAttrs' (name: hub: lib.nameValuePair "claude-${name}-hub" (mkHub name hub)) hubs;
    };
  };
}

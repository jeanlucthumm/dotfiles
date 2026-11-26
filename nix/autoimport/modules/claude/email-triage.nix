# Email triage router: at 08:00 and 18:00 a headless Haiku reads new inbox
# mail, archives junk, collects unsubscribe candidates and sends the chore hub
# one batched message. Its prompt, last-run timestamp and unsubscribe list
# live in the vault (chore/system/triage/), so the judgement can be tuned
# without a deploy. This file owns the tool list, which is the security
# boundary: email is untrusted input.
#
# Manual run: email-triage [--dry-run]. Logs: journalctl --user -u email-triage,
# full transcripts in ~/.local/state/email-triage/logs.
_: {
  flake.modules.nixos.homeServer = {
    home-manager.users.jeanluc = {
      config,
      lib,
      pkgs,
      ...
    }: let
      vault = "/home/jeanluc/obsidian/vault";
      gmail = "mcp__claude_ai_Gmail__";

      # Archiving (unlabel_thread) is added by the script, outside dry runs.
      allowed = [
        "ToolSearch"
        "ListAgents"
        "SendMessage"
        "${gmail}search_threads"
        "${gmail}get_thread"
      ];
      denied =
        [
          "mcp__claude_ai_Google_Calendar"
          "mcp__claude_ai_Google_Drive"
          "mcp__claude_ai_Granola"
          "mcp__claude_ai_Claude_Docs"
        ]
        ++ map (t: gmail + t) [
          "send_message"
          "reply"
          "forward"
          "create_draft"
          "update_draft"
          "trash_thread"
          "trash_message"
          "mark_thread_spam"
          "mark_message_spam"
          "delete_label"
        ];

      # SendMessage skips permission checks (dontAsk and the allowlist don't
      # apply to it), so this hook is what keeps the router from messaging
      # any session but the hub.
      hubOnly = pkgs.writeShellScript "email-triage-hub-only" ''
        if ${pkgs.jq}/bin/jq -e '(.tool_input.to // "" | startswith("hub-"))
          and (.tool_input.recipient // "hub-" | startswith("hub-"))' >/dev/null; then
          exit 0
        fi
        echo "Blocked: the triage router may only message the hub-* session." >&2
        exit 2
      '';
      settings = builtins.toJSON {
        hooks.PreToolUse = [
          {
            matcher = "SendMessage";
            hooks = [
              {
                type = "command";
                command = "${hubOnly}";
              }
            ];
          }
        ];
      };

      schema = builtins.toJSON {
        type = "object";
        required = ["hub_message_sent" "escalated" "archived" "unsubscribe"];
        properties = {
          hub_message_sent.type = "boolean";
          escalated.type = "integer";
          archived.type = "integer";
          unsubscribe = {
            type = "array";
            items = {
              type = "object";
              required = ["name" "email" "link"];
              properties = {
                name.type = "string";
                email.type = "string";
                link.type = "string";
              };
            };
          };
        };
      };

      triage = pkgs.writeShellApplication {
        name = "email-triage";
        runtimeInputs = with pkgs; [coreutils findutils gnugrep jq];
        text =
          ''
            claude=${config.jl.claude.package}/bin/claude
            dir=${vault}/chore/system/triage
            chores=${vault}/chore/INDEX.md
            state=${config.xdg.stateHome}/email-triage
            allowed=(${lib.escapeShellArgs allowed})
            denied=(${lib.escapeShellArgs denied})
            settings=${lib.escapeShellArg settings}
            schema=${lib.escapeShellArg schema}
          ''
          + builtins.readFile ./email-triage.sh;
      };
    in {
      home.packages = [triage];

      systemd.user.services.email-triage = {
        Unit.Description = "Email triage router (headless Claude)";
        Service = {
          Type = "oneshot";
          ExecStart = "${triage}/bin/email-triage";
          TimeoutStartSec = "30min";
        };
      };

      systemd.user.timers.email-triage = {
        Unit.Description = "Email triage at 08:00 and 18:00";
        Timer = {
          OnCalendar = ["*-*-* 08:00:00" "*-*-* 18:00:00"];
          # A run missed while the server was down happens at boot.
          Persistent = true;
        };
        Install.WantedBy = ["timers.target"];
      };
    };
  };
}

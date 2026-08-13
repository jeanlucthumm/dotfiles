# `awake` — keep a Mac awake through lid close for a bounded time.
#
# `caffeinate`-style IOPM assertions cannot block lid-close sleep; only
# `pmset disablesleep 1` can, and that setting is dangerous because it does
# not expire (hot laptop in a bag). This module makes it safe to use:
#
#   awake 2h      # disable sleep, auto-restore after 2 hours
#   awake off     # restore immediately
#   awake status  # show state and remaining time
#
# Safety comes from three layers:
#   1. A detached root watchdog resets `disablesleep` at the deadline.
#   2. The deadline lives in /var/db/awake/deadline; re-arming or cancelling
#      rewrites it, and stale watchdogs exit when their deadline no longer
#      matches the file.
#   3. A RunAtLoad launchd daemon re-arms the watchdog after a reboot or
#      rebuild, or resets the setting if the deadline has passed.
#
# A NOPASSWD sudoers rule is scoped to the helper's exact store path, so the
# user CLI (and later automation like a Hammerspoon menubar) never prompts.
{
  flake.modules.darwin.base = {pkgs, ...}: let
    helper = pkgs.writeShellScriptBin "awake-helper" ''
      # Root-only mechanism for `awake`. All state transitions live here so
      # the sudoers rule covers one binary.
      set -u

      STATE_DIR=/var/db/awake
      DEADLINE_FILE=$STATE_DIR/deadline

      spawn_watchdog() {
        /usr/bin/nohup "$0" watchdog "$1" >/dev/null 2>&1 &
      }

      case "''${1:-}" in
        on)
          secs="''${2:-}"
          case "$secs" in
            "" | *[!0-9]*)
              echo "awake-helper: bad seconds: $secs" >&2
              exit 1
              ;;
          esac
          /bin/mkdir -p "$STATE_DIR"
          /bin/chmod 755 "$STATE_DIR"
          deadline=$(($(/bin/date +%s) + secs))
          echo "$deadline" >"$DEADLINE_FILE"
          /bin/chmod 644 "$DEADLINE_FILE"
          /usr/bin/pmset -a disablesleep 1
          spawn_watchdog "$deadline"
          ;;

        off)
          /bin/rm -f "$DEADLINE_FILE"
          /usr/bin/pmset -a disablesleep 0
          ;;

        watchdog)
          deadline="''${2:-0}"
          while true; do
            current=$(/bin/cat "$DEADLINE_FILE" 2>/dev/null || echo 0)
            # Cancelled or re-armed with a new deadline: this watchdog is stale.
            [ "$current" = "$deadline" ] || exit 0
            now=$(/bin/date +%s)
            if [ "$now" -ge "$deadline" ]; then
              /bin/rm -f "$DEADLINE_FILE"
              /usr/bin/pmset -a disablesleep 0
              exit 0
            fi
            left=$((deadline - now))
            /bin/sleep $((left < 30 ? left : 30))
          done
          ;;

        resume)
          # After boot or darwin-rebuild: the old watchdog process may be
          # gone. Re-arm for the remaining window, or clean up.
          now=$(/bin/date +%s)
          current=$(/bin/cat "$DEADLINE_FILE" 2>/dev/null || echo 0)
          if [ "$current" -gt "$now" ] 2>/dev/null; then
            /usr/bin/pmset -a disablesleep 1
            spawn_watchdog "$current"
          else
            /bin/rm -f "$DEADLINE_FILE"
            /usr/bin/pmset -a disablesleep 0
          fi
          ;;

        *)
          echo "usage: awake-helper on <seconds> | off | resume" >&2
          exit 1
          ;;
      esac
    '';

    awake = pkgs.writeShellScriptBin "awake" ''
      set -u

      DEADLINE_FILE=/var/db/awake/deadline
      HELPER=${helper}/bin/awake-helper

      status() {
        disabled=$(/usr/bin/pmset -g | /usr/bin/awk '/SleepDisabled/ {print $2}')
        if [ "''${disabled:-0}" != 1 ]; then
          echo "sleep: normal"
          return
        fi
        deadline=$(/bin/cat "$DEADLINE_FILE" 2>/dev/null || echo 0)
        now=$(/bin/date +%s)
        if [ "$deadline" -gt "$now" ] 2>/dev/null; then
          echo "sleep: disabled, $(((deadline - now + 59) / 60))m remaining"
        else
          # disablesleep is on but no live window — set outside of awake,
          # or the watchdog died. Either way it will not expire on its own.
          echo "sleep: disabled with NO deadline — run 'awake off'"
        fi
      }

      case "''${1:-status}" in
        status)
          status
          ;;

        off)
          sudo "$HELPER" off
          echo "sleep: normal"
          ;;

        *)
          arg=$1
          case "$arg" in
            *h) secs=$((''${arg%h} * 3600)) ;;
            *m) secs=$((''${arg%m} * 60)) ;;
            *s) secs=''${arg%s} ;;
            *[!0-9]*)
              echo "usage: awake [<n>h|<n>m|<n>s|<minutes>] | off | status" >&2
              exit 1
              ;;
            *) secs=$((arg * 60)) ;;
          esac
          if [ "$secs" -le 0 ] 2>/dev/null; then
            echo "awake: bad duration: $arg" >&2
            exit 1
          fi
          if /usr/bin/pmset -g batt | /usr/bin/head -1 | /usr/bin/grep -q "Battery Power"; then
            echo "note: on battery — the machine stays fully on until the deadline" >&2
          fi
          sudo "$HELPER" on "$secs"
          status
          ;;
      esac
    '';
  in {
    environment.systemPackages = [awake];

    # Exact store path, so only this helper is passwordless. The path changes
    # on every edit, but the rule regenerates with it in the same generation.
    security.sudo.extraConfig = ''
      %admin ALL=(root) NOPASSWD: ${helper}/bin/awake-helper *
    '';

    launchd.daemons.awake-resume = {
      serviceConfig = {
        ProgramArguments = ["${helper}/bin/awake-helper" "resume"];
        RunAtLoad = true;
        # The resume path spawns a detached watchdog; without this, launchd
        # kills it as soon as the daemon exits.
        AbandonProcessGroup = true;
      };
    };
  };
}

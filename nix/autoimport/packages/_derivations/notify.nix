{
  lib,
  writeShellApplication,
  stdenv,
  libnotify,
}:
writeShellApplication {
  name = "notify";

  # Linux uses libnotify; macOS uses the OS-bundled osascript, so no nix
  # dependency at all. (This used terminal-notifier, but it's abandoned
  # upstream and its ancient Xcode project stopped linking under newer
  # nixpkgs darwin toolchains — cctools ld crashes with SIGTRAP.)
  runtimeInputs = lib.optionals (!stdenv.isDarwin) [libnotify];

  text = let
    darwinPrelude = ''
      # Escape for embedding in an AppleScript double-quoted string.
      esc() {
        local s=$1
        s=''${s//\\/\\\\}
        s=''${s//\"/\\\"}
        printf '%s' "$s"
      }
    '';
    send =
      if stdenv.isDarwin
      then ''
        cmd="display notification \"$(esc "$message")\""
        if [[ -n "$title" ]]; then
          cmd+=" with title \"$(esc "$title")\""
        fi
        if [[ -n "$sound" ]]; then
          cmd+=" sound name \"$(esc "$sound")\""
        fi
        /usr/bin/osascript -e "$cmd"
      ''
      else ''
        args=()
        if [[ -n "$sound" ]]; then
          # Best effort: honored only by notification daemons that support
          # the freedesktop sound-name hint.
          args+=(-h string:sound-name:bell)
        fi
        if [[ -n "$title" ]]; then
          notify-send "''${args[@]}" "$title" "$message"
        else
          notify-send "''${args[@]}" "$message"
        fi
      '';
  in ''
    ${lib.optionalString stdenv.isDarwin darwinPrelude}
    title=""
    message=""
    sound=""

    usage() {
      cat <<'EOF'
    Usage: notify [-t|--title TITLE] [-s|--sound[=NAME]] MESSAGE

    Send a desktop notification (osascript on macOS, notify-send on Linux).

    Options:
      -t, --title TITLE   Set the notification title
      -s, --sound         Play the default sound (Glass) with the notification
          --sound=NAME    Play a specific macOS sound (e.g. Funk, Ping);
                          best-effort sound-name hint on Linux
      -h, --help          Show this help
    EOF
    }

    # Parse arguments
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -h|--help)
          usage
          exit 0
          ;;
        -t|--title)
          title="$2"
          shift 2
          ;;
        -s|--sound)
          sound="Glass"
          shift
          ;;
        --sound=*)
          sound="''${1#--sound=}"
          shift
          ;;
        *)
          message="$1"
          shift
          ;;
      esac
    done

    if [[ -z "$message" ]]; then
      usage >&2
      exit 1
    fi

    ${send}
  '';

  meta = {
    description = "Cross-platform notification wrapper (libnotify on Linux, osascript on macOS)";
    platforms = lib.platforms.unix;
  };
}

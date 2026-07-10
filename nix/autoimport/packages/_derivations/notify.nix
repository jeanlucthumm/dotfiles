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
    withTitle =
      if stdenv.isDarwin
      then ''/usr/bin/osascript -e "display notification \"$(esc "$message")\" with title \"$(esc "$title")\""''
      else ''notify-send "$title" "$message"'';
    withoutTitle =
      if stdenv.isDarwin
      then ''/usr/bin/osascript -e "display notification \"$(esc "$message")\""''
      else ''notify-send "$message"'';
  in ''
    ${lib.optionalString stdenv.isDarwin darwinPrelude}
    title=""
    message=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -t|--title)
          title="$2"
          shift 2
          ;;
        *)
          message="$1"
          shift
          ;;
      esac
    done

    if [[ -z "$message" ]]; then
      echo "Usage: notify [-t|--title TITLE] MESSAGE" >&2
      exit 1
    fi

    if [[ -n "$title" ]]; then
    	${withTitle}
    else
    	${withoutTitle}
    fi
  '';

  meta = {
    description = "Cross-platform notification wrapper (libnotify on Linux, osascript on macOS)";
    platforms = lib.platforms.unix;
  };
}

{
  lib,
  writeShellApplication,
  stdenv,
  libnotify,
  terminal-notifier,
}:
writeShellApplication {
  name = "notify";

  runtimeInputs =
    if stdenv.isDarwin
    then [terminal-notifier]
    else [libnotify];

  text =
    if stdenv.isDarwin
    then ''
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
        terminal-notifier -title "$title" -message "$message"
      else
        terminal-notifier -message "$message"
      fi
    ''
    else ''
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
        notify-send "$title" "$message"
      else
        notify-send "$message"
      fi
    '';

  meta = {
    description = "Cross-platform notification wrapper (libnotify on Linux, terminal-notifier on macOS)";
    platforms = lib.platforms.unix;
  };
}

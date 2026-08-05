Use `notify` CLI

```
Usage: notify [-t|--title TITLE] [-s|--sound[=NAME]] MESSAGE

Send a desktop notification (osascript on macOS, notify-send on Linux).

Options:
  -t, --title TITLE   Set the notification title
  -s, --sound         Play the default sound (Glass) with the notification
      --sound=NAME    Play a specific macOS sound (e.g. Funk, Ping);
                      best-effort sound-name hint on Linux
  -h, --help          Show this help
```

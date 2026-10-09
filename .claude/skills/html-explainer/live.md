# Live comments (experimental)

The reader's comments reach this session as they're written, and replies render in the comment's thread on the page. Needs the explainer open in a terminal-browser pane. Shared copies and plain Chrome don't get it; there, comments fall back to Copy all.

1. Open the pane beside your own kitty window without stealing focus. Your tab may not be the active one:
   `kitten @ launch --match id:<tab> --keep-focus --location=vsplit --bias=45 -- terminal-browser open <file> --parent-tty=/dev/<your tty>`
   Get the tab id and your window from `kitten @ ls`, your tty from `ps -o tty= -p <window pid>`, and the key from `terminal-browser ls --all --json`.
2. Arm a Monitor (30 min max, re-arm on expiry) on `scripts/zc-live-watch.sh <key>`. Polling is what lights the page's "live" badge. While the badge shows, new comments queue for you instead of waiting for Copy all.
3. Each event is one comment or follow-up, given as JSON with `n`, `anchor`, `section`, `text` and `followUp`. Reply with:
   `scripts/zc-live-reply.sh <key> <n> <<'MD' ... MD`
   The reply supports paragraphs, `-` lists, inline code, **bold** and fenced code. Keep it short, like a margin note.
4. If the comment asks for a change to the page, edit the file and reply saying what changed. Then run `action -- eval "location.reload()"`. Threads survive a reload because they live in localStorage.

A `{"closed":true}` event means the pane is gone, so stop.

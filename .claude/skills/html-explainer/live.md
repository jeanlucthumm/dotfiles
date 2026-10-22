# Live comments (experimental)

The reader's comments reach this session as they're written, and replies render in the comment's thread on the page. Two transports: a terminal-browser pane (below), or any browser through a local relay (last section). Shared copies without either fall back to Copy all.

1. Open the pane beside your own kitty window without stealing focus. Your tab may not be the active one:
   `kitten @ launch --match id:<tab> --keep-focus --location=vsplit --bias=45 -- terminal-browser open <file> --parent-tty=/dev/<your tty>`
   Get the tab id and your window from `kitten @ ls`, your tty from `ps -o tty= -p <window pid>`, and the key from `terminal-browser ls --all --json`.
2. Arm a Monitor (30 min max, re-arm on expiry) on `scripts/zc-live-watch.sh <key>`. Polling is what lights the page's "live" badge. While the badge shows, new comments queue for you instead of waiting for Copy all.
3. Each event is one comment or follow-up, given as JSON with `n`, `anchor`, `section`, `text` and `followUp`. Reply with:
   `scripts/zc-live-reply.sh <key> <n> <<'MD' ... MD`
   The reply supports paragraphs, `-` lists, inline code, **bold** and fenced code. Keep it short, like a margin note.
   The reader is reading the page, so your chat message after a reply is just `OK`. No paraphrase, no comment number, no side notes: anything else is noise they have to skim twice.
4. If the comment asks for a change to the page, edit the file and reply saying what changed. Then run `action -- eval "location.reload()"`. Threads survive a reload because they live in localStorage, and the thread the reader had open reopens.

A `{"closed":true}` event means the pane is gone, so stop.

## Any browser (Chrome) through the local relay

Use this when the reader is in their own browser. The page needs `assets/zc-bridge.js` loaded after `comment-layer.js`; it stays dormant unless the URL carries `?live`, so pages without a relay make no requests.

1. Start the relay in a background Bash: `python3 scripts/zc-bridge-server.py` (port 47321; pass another as the first argument and set `window.zcBridgePort` on the page). It holds queues in memory and serves only `file://` pages and non-browser clients, so other sites can't read replies or plant comments.
2. The reader opens the page with `?live` before any `#hash`, e.g. `file:///path/page.html?live#node`. Their comments, localStorage and threads stay put: same origin as without it.
3. Arm a Monitor (30 min max, re-arm on expiry) on `scripts/zc-bridge-watch.sh`. Its drains light the "live" badge; events have the same shape as in terminal-browser mode.
4. Reply with `scripts/zc-bridge-reply.sh <n> <<'MD' ... MD`. After editing the page, `scripts/zc-bridge-reply.sh reload` reloads it. Same reply style as above: short margin notes, and just `OK` in chat.

Long comments arrive truncated in the Monitor notification (`...(truncated)`). The full line is the last one in the Monitor task's output file: `tail -n 1 <output file> | jq -r .text`.

Never health-check the relay with `/page/poll` or `/session/drain`: both consume their queue (a poll takes replies meant for the page). A curl to `/` returning 404 shows it is up.

A `{"closed":true}` event means the relay is gone. Restart it and re-arm.

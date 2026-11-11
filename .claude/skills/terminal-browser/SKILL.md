---
name: terminal-browser
description: Show the user a URL, HTML or Markdown file in a browser pane inside their kitty terminal and drive it programmatically. Use when the user wants to see something without leaving the terminal, or for split-pane show-and-tell. Not for testing in Chrome.
---

`terminal-browser open <url|file>` shows a page in a kitty pane; `terminal-browser action --browser <key> -- <agent-browser cmd>` drives it (snapshot, click @eN, eval, screenshot, wait --fn). Reference: `terminal-browser help`, `terminal-browser <cmd> --help`.

Placement: `open --split right --size 0.4` splits the *active* kitty tab and fails without a tty, so from a background session launch through kitty instead:
`kitten @ launch --match id:<tab> --keep-focus --location=vsplit --bias=40 -- terminal-browser open <file> --parent-tty=/dev/<tty>`
Your tty is the first ancestor process with one; match it to a window pid in `kitten @ ls` for the tab. No kitty window of your own: `--type=tab --keep-focus` instead of the split.

Gotchas:

- Plain `ls` is scoped to your tab and empty from a tty-less shell. Use `ls --all --json` for `key` and `pane.pane`, and pass `--browser <key>` everywhere.
- One daemon serves every pane: never `kill` its pid. Teardown is `kitten @ close-window --match id:<pane.pane>`; `action -- close` only closes the tab.
- One `action` at a time per browser; a pending `wait` misses changes made by a concurrent one.
- Every `action` lights the pane's blue "agent is driving" outline for 10s. Run `action --browser <key> done` after your last one.
- `.md` files render styled (mermaid included, scripts blocked). Open the file directly to show a plan or notes rather than building HTML. The page is transparent, so `screenshot` shows black where the user sees their terminal.
- A prompt like `[<li>…</li> selector: body > ul > li]` with a screenshot attached came from grab mode (ctrl+g): the user pointed at that element.
- `kitten @` can't connect to `/tmp/kitty-NNN`: kitty restarted. Point `KITTY_LISTEN_ON` at the live `/tmp/kitty-*` socket.
- WebGL, file URLs and `#deep=links` all work.
- Linux hosts don't have it installed; give a file URL instead.

---
name: terminal-browser
description: Show the user a URL or HTML file in a browser pane inside their terminal (kitty split) and drive it programmatically. Use when the user wants to see something visual without leaving the terminal, or for split-pane show-and-tell workflows.
---

# terminal-browser

Show the user web content in a terminal split pane: `terminal-browser open <url|port|file.html> --split right --size 0.4`.

Gotchas:

- `open` prints JSON. Save `key` and `pid` from it; you need both later.
- You run in a different terminal tab than the pane, so every `action` call needs `--browser <key>`. Without it you get "no terminal browser in this terminal tab".
- Drive the pane with the agent-browser command set: `terminal-browser action --browser <key> -- navigate <url>` / `eval <js>` / `snapshot` / `click @eN`.
- Plain `ls` is tab-scoped and will say "no terminal browsers running" even when yours is alive. Use `ls --all`.
- `action -- close` closes the tab, NOT the instance; the pane stays. Teardown is `kill <pid>`.
- WebGL works in the pane (verified with a three.js scene).
- File URLs and `#deep=links` both work in `navigate`.
- New kitty tab instead of a split: `kitten @ launch --type=tab --tab-title "..." terminal-browser open <file>` (it renders in whatever pane it starts in). Grab the new key from `ls --all`.

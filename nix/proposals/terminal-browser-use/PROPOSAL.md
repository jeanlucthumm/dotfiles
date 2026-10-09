# Better use of terminal-browser

Status: proposal, not started.
Date: 2026-10-06

Admission bar: how the skills in `~/.claude/skills` and the Nix config should
use terminal-browser, backed by behaviour verified on v0.13.4. Upstream
packaging work (the flake PR) stays in the fork branch, not here.

## Trigger

Four skills already lean on the pane: `terminal-browser` (open and drive),
`stepwise-explainer` (one card at a time, paced by acks in chat),
`pr-walkthrough` (cards plus the reader comment layer) and `html-explainer`
(single-file explainers with the same comment layer). They were written
against v0.3.x. A lab session on 2026-10-06 against v0.13.4 found that
several of their instructions are now wrong or dangerous, and that the pane
can do more than they ask of it. Lab page and helper scripts are in
`~/Code/tb-lab/` (NOTES.md has the raw findings).

## What changed underneath the skills

Verified unless marked otherwise.

- One Electron daemon now serves every pane. `ls --all --json` shows the
  same `pid` for every browser. The skill's teardown, `kill <pid>`, would
  kill every open browser on the machine. `kitten @ close-window --match
  id:<pane>` closes one pane and leaves the rest running.
- `terminal-browser open --split right` splits the *active* kitty tab. When
  the agent lives in a background tab (a background job, or the user has
  switched away) the pane lands in whatever the user is looking at.
  `kitten @ launch --match id:<tab> --keep-focus --location=vsplit --bias=45
  -- terminal-browser open <file> --parent-tty=<agent tty>` puts it next to
  the agent and leaves focus alone.
- From a shell with no tty, `ls` is tab-scoped and empty. Always `ls --all`
  and pass `--browser <key>` to every `action`, `new-tab` and `done`.
- `action -- wait --fn "<js>"`, `wait --text` and `wait <selector>` block
  for up to 25s and see main-world globals. They only miss a change when a
  second `action` runs against the same browser while the wait is pending.
  One `action` at a time per browser.
- `new-tab --browser <key> <url>` adds a tab; `action --tab N` targets it;
  `action -- tab close N` removes it. A card deck can be one pane with the
  cards as tabs instead of repeated `navigate`.
- `action --browser <key> done` clears the "agent is using this tab" badge.
- Page to agent is designed as "put text in the prompt, the human presses
  Enter". Grab mode (ctrl+g, click an element) types `> <content>` into the
  parent pane under bracketed paste, which never submits. The grab binding
  only accepts messages while grab mode is active, so a page button cannot
  piggyback on it. Any auto-submitting helper has to type a bare `\r` into
  the agent pane; Claude Code's auto-mode classifier refuses to let the
  agent start such a helper against its own pane, so only the human can.
- WebMCP (`navigator.modelContext`) is undefined on `file://` and `https://`
  pages in this build even though Electron is launched with the flag. Not
  usable yet.
- Shortcuts and settings live in `~/.config/terminal-browser/{shortcuts,
  settings}.json`, also editable with `terminal-browser config set`. The
  Nix config already ships `shortcuts.json` declaratively (palette on
  ctrl+p); that makes the in-app settings UI read-only.
- Record mode (ctrl+r, ctrl+enter to finish) writes
  `/tmp/recordings/<host>-<HHMMSS>/` with a manifest and copies the path to
  the clipboard.

## Proposal

### 1. Fix the `terminal-browser` skill text

Cheap and overdue. Replace the gotchas list with:

- `open` prints the instance record; keep `key` and `pane.pane`, not `pid`.
- Teardown is `kitten @ close-window --match id:<pane>`. Never `kill`.
- `ls --all` and `--browser <key>` everywhere; `action done` when finished.
- One `action` at a time per browser; `wait --fn` for blocking on page
  state; `screenshot /abs/path.png` then read the image to verify layout.
- Prefer `new-tab --browser` over `navigate` when the user may want to go
  back.
- Do not use WebMCP yet; drop the `kill <pid>` and `kitten launch
  --type=tab` advice in favour of the helper below.

### 2. `tb-open`: one way to put a page beside the agent

A small script (nushell under `autoimport/modules/nushell/scripts/`, or a
derivation under `autoimport/packages/`) that every skill calls instead of
raw `terminal-browser open`:

- Resolve the agent pane: `KITTY_WINDOW_ID` when set, otherwise walk the
  process tree for a tty (the same trick terminal-browser's own CLI uses)
  and match it against `kitten @ ls`.
- `kitten @ launch --match id:<tab> --keep-focus --location=vsplit
  --bias=<size> -- terminal-browser open <target> --parent-tty=<tty>`.
- Poll `ls --all --json` until the new key appears, then print
  `{key, pane, tab, targetId}` as one JSON line.
- Reuse: with `--reuse <key>` call `new-tab --browser <key>` instead.
- `tb-close <key>` wraps the `close-window` teardown.

### 3. Pull comments and decisions instead of paste-back

The comment layer (`html-explainer/assets/comment-layer.js`) builds a
payload and asks the human to copy it and paste it into chat. Replace that
round trip:

- Expose `window.zcCollect()` that returns the payload text and clears the
  store (the "Copy & clear" button stays as a fallback for a dead session).
- Add a "Done" button that sets `document.body.dataset.zcDone = "1"`.
- The agent runs `action --browser <key> -- wait --fn
  "document.body.dataset.zcDone"` in a loop (each call times out at 25s),
  then `eval "zcCollect()"`. No clipboard, no paste, works while the agent
  is mid-turn.
- `pr-walkthrough` and `html-explainer` adopt it directly. `review-guide`
  already sketched the same pull in its parked design; this is the minimal
  version of it.

### 4. Cards with buttons in `stepwise-explainer`

Today a card advances on an ack typed in chat. Add Next, Back and Question
buttons to the card template that set `document.body.dataset.step`, and
have the skill wait on that marker between cards. Chat acks keep working;
the buttons just remove the need to switch focus for the common case.
Pair with the one-pane-many-tabs mode from section 2 so Back is a real tab
switch.

### 5. Nix config

- Add a declarative `settings.json` next to `shortcuts.json` with
  `updates.check = "off"`. The Nix install is read-only, `terminal-browser
  upgrade` cannot work, and the update nag is noise.
- Keep the flake input on the fork branch until the upstream flake PR
  lands, then flip the URL. `dev.nix` already carries that comment.
- The flake is `aarch64-darwin` only. Linux hosts stay without the pane
  until the Linux tarball is ELF-patched; note it in the skill so the agent
  falls back to a file URL on those hosts.

### 6. Later

- Grab mode as the "quote this element" path. Document ctrl+g in the skills
  so the agent knows the `> ...` lines in a prompt came from the page.
- Record mode for repro capture: a skill that asks the human to record,
  then reads the manifest from `/tmp/recordings/`.
- The official Claude Code plugin (`claude-bridge`) renders the browser
  inside the Claude Code TUI and has an inbox that fills the prompt. It
  needs `CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1` and is marked experimental.
  Revisit when the mods API in `proposals/claude-mods/` settles.
- WebMCP: when `navigator.modelContext` appears, explainer pages can publish
  `get_state` and `set_*` tools and the agent can use `action -- webmcp
  invoke` instead of snapshot and click.
- Move `~/Code/tb-lab/lab.html` into the `terminal-browser` skill as a
  channel self-test once the skill is edited.

### 3b. Live comments (built 2026-10-08, experimental)

`/html-explainer --live`: a Monitor runs `scripts/zc-live-watch.sh <key>`, which polls
`zcLive.drain()` through `action -- eval` every 1.5s. Each new comment or follow-up wakes
the session as an event. The session answers with `scripts/zc-live-reply.sh`, which calls
`zcLive.answer(n, md)`, and the reply renders in the comment's thread. Polling doubles as
the heartbeat, so the page shows "live" only while a session listens and falls back to
Copy & clear otherwise. Verified on v0.13.4: a reply eval running alongside the poller
works, and threads survive a reload. No helper types into the agent pane, so the
self-drive block does not apply. WebMCP was re-checked the same day and is still absent.

## Order

1. Section 1, skill text. One edit, removes the `kill` footgun.
2. Section 3, comment pull. Small JS change plus two skill edits.
3. Section 2, `tb-open`. Needed before any skill runs from a background job.
4. Section 5, `settings.json`.
5. Section 4, card buttons.
6. Section 6 as upstream moves.

## Open questions

- Does `wait --fn` need re-arming after `navigate` loads a new card in the
  same tab, or is one wait per card enough? Expected: one per card, since
  the wait is issued after the navigate.
- Is the one-action-at-a-time rule per browser or per daemon? Two browsers
  on one daemon were driven from two sessions today without trouble, so
  probably per browser. Unverified.
- Whether to keep ack pacing in chat as the default and make buttons opt-in,
  or the reverse. Try buttons on a few decks first.

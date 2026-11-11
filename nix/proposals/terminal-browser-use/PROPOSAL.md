# Better use of terminal-browser

Status: proposal. Live comments built (section 3), the rest not started.
Date: 2026-10-06, updated 2026-11-09 for v0.15.3.

Admission bar: how the skills in `~/.claude/skills` and the Nix config should
use terminal-browser, backed by behaviour verified on v0.13.4 or read from the
v0.15.3 source (marked). Upstream packaging work (the flake PR) stays in the
fork branch, not here.

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

## What v0.15 adds

Read from the v0.15.3 source on 2026-11-09. `.md` rendering and grab
screenshots have since been run on this machine.

- Grab mode sends a screenshot (verified 2026-11-11). The text is now
  `[<element html> selector: <css path>]`; the `> ` prefix is gone. In kitty
  it copies a PNG of the element to the clipboard and sends ctrl+v to the
  agent pane, so Claude Code attaches it. It overwrites the clipboard, and
  in the test the image arrived twice. A file is written only when pasting
  isn't possible.
- `.md` files render as styled pages: code highlighting, mermaid blocks,
  GitHub alerts, task lists, terminal theme colours. Scripts are blocked
  (`script-src 'none'`), so no comment layer and no live mode on them. HTML
  files still load as `file://`, so explainers and their localStorage threads
  are unaffected.
- `TERMINAL_BROWSER_NO_CHROME=1` drops the toolbar, padding and frame. The
  browser reads it from the environment of the `open` call, so it should
  apply per pane. With no frame, the blue agent outline probably has nowhere
  to draw. Both untested.
- Tab next and previous shortcuts. `ctrl+tab` never reaches the browser
  because kitty's default binds it to `next_tab`; `cmd+alt+left/right` do.
- On the first run of each new version, the CLI links upstream's own skill
  into `~/.agents/skills` and `~/.codex/skills` (and `.cursor`, `.gemini`
  when present). It skips real directories, so our
  `~/.claude/skills/terminal-browser` is untouched. That bundled skill is
  the version's `--help` text plus "run `action done` when finished" and
  WebMCP guidance. Opt out by writing `no` to
  `~/.local/state/terminal-browser/skills-choice`.
- Settings worth knowing: `updates.check`, `telemetry.usage`,
  `telemetry.crashReports`, `window.transparent`. `DO_NOT_TRACK=1` or
  `TERMINAL_BROWSER_NO_TELEMETRY=1` turn telemetry off without a settings
  file.
- No skill impact: clicks reaching iframes (captchas work), site permission
  prompts, Google sign-in popups, `clear-browsing-data`, zoom, new terminal
  backends. There is still no setting for the agent outline, and WebMCP is
  still absent from the browser source (re-check on the new Electron).

## Proposal

### 1. Rewrite the `terminal-browser` skill as a thin layer (done)

Done 2026-11-09. The skill keeps only what upstream's help text doesn't
cover (background placement, teardown, one action at a time, `action done`,
`.md` viewing, grab lines) and points at `terminal-browser help` for
commands.

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
- `--bare` sets `TERMINAL_BROWSER_NO_CHROME=1` on the `open` call, once
  that is tested. Cards and explainers don't need a URL bar.
- `tb-close <key>` wraps the `close-window` teardown.

### 3. Live comments instead of paste-back (built)

`/html-explainer --live`, built 2026-10-08. A Monitor runs
`scripts/zc-live-watch.sh <key>`, which polls `zcLive.drain()` every 1.5s;
each new comment or follow-up wakes the session as an event, and
`scripts/zc-live-reply.sh` renders the answer in the comment's thread.
Polling doubles as the heartbeat, so the page shows "live" only while a
session listens and falls back to Copy & clear otherwise. Since 2026-10-13
the watcher polls the bundled agent-browser directly, because polling
through `action` kept the outline lit. No helper types into the agent
pane, so the self-drive block does not apply. This replaced the planned
`zcCollect()` plus Done-button pull.

### 4. Cards with buttons in `stepwise-explainer`

Today a card advances on an ack typed in chat. Add Next, Back and Question
buttons to the card template that set `document.body.dataset.step`, and
have the skill wait on that marker between cards. Chat acks keep working;
the buttons just remove the need to switch focus for the common case.
Pair with the one-pane-many-tabs mode from section 2 so Back is a real tab
switch (the user can also flip tabs with `cmd+alt+left/right`), and with
`--bare` so a card is only the card.

### 5. Nix config

- Optional: a declarative `settings.json` next to `shortcuts.json` with
  `"updates.check": "off"` (flat dotted keys). The check is one request per
  launch, and its only visible effect is a green "update available, run
  `terminal-browser upgrade`" line in Settings, which is wrong advice on a
  read-only Nix install. Low value alone; worth doing only together with the
  telemetry question below.
- Leave the upstream skill links alone. They never touch our Claude skill,
  they follow the installed version, and Codex gets a working skill for free.
- Keep the flake input on the fork branch until the upstream flake PR
  lands, then flip the URL. `dev.nix` already carries that comment.
- The flake is `aarch64-darwin` only. Linux hosts stay without the pane
  until the Linux tarball is ELF-patched; note it in the skill so the agent
  falls back to a file URL on those hosts.

### 6. Later

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

## Order

1. A short test on v0.15.3: `NO_CHROME` per pane and whether it hides the
   outline, a grab screenshot arriving in Claude Code, live mode still
   working, WebMCP on the new Electron.
2. Section 2, `tb-open` (with `--bare` if step 1 passes). Needed before any
   skill runs from a background job.
3. Section 4, card buttons.
4. Section 5 if the telemetry question lands on "off".
5. Section 6 as upstream moves.

## Open questions

- Does `wait --fn` need re-arming after `navigate` loads a new card in the
  same tab, or is one wait per card enough? Expected: one per card, since
  the wait is issued after the navigate.
- Is the one-action-at-a-time rule per browser or per daemon? Two browsers
  on one daemon were driven from two sessions today without trouble, so
  probably per browser. Unverified.
- Whether to keep ack pacing in chat as the default and make buttons opt-in,
  or the reverse. Try buttons on a few decks first.
- Turn telemetry off in the same `settings.json`? Upstream's events are
  anonymous and logged locally for audit, so this is a preference, not a fix.

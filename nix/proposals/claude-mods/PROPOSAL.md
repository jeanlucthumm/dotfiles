# Claude Code mods for the dotfiles

Status: proposal, not started.
Date: 2026-10-05

Admission bar: public, machine-agnostic Claude Code hooks and UI that any
host of this flake can load. Replit-specific pollers (PR watcher, rollout
watch, oncall loop) are in `dotfiles-private/proposals/claude-mods.md`.

## Trigger

Claude Code 2.1.289 release notes: "Added Claude Mods: plugins may now
modify deeper behavior." A mod is a plugin whose hooks are a TypeScript
module the engine loads in-process and hot-reloads. `on(event, hook)`
registers a hook, and every hook is `($, e, next)`: `$` is the engine API,
`e` the event input, `next(e)` the engine's default behaviour. A hook can
deny or rewrite tool calls, change prompts, register slash commands and
model-callable tools, run timers and host processes, and draw panes, bands,
status entries and toasts on every surface (terminal, desktop, VS Code,
mobile). An audit of this repo and `~/.claude` found three things worth
moving and several not worth it.

## How a mod loads here

- Three files: `.claude-plugin/plugin.json`, `hooks/hooks.json`
  (`{"modules": ["./register.tsx"]}`), `hooks/register.tsx`. A mod that
  keeps `$.state` adds `types/index.d.ts` as its contract.
- A plugin folder under `~/.claude/skills/<name>/` auto-loads and is
  watched in interactive sessions, so public mods are yadm-tracked there
  like every other skill. No settings change.
- The engine writes `.claude-plugin/types/` beside a loaded mod (editor
  types and a tsconfig). Add `.claude/skills/*/.claude-plugin/types/` to
  `~/.gitignore` (yadm's worktree ignore).
- The server agent gets its mod via `--plugin-dir` (item 3).
- Check with `claude plugin validate <dir>`, `tsc -p <dir>`,
  `claude plugin test <dir>`.
- The bundled `plugin-authoring` skill is the reference. Its types file
  documents every event and `$` method; grep it for the name at hand.

## 1. jj-git-rewrite as a `tool.call` hook (replace, small)

Today: `autoimport/modules/claude/_jj-git-rewrite.py`, forked by a
PreToolUse shell hook on every Bash call (wired in `claude-code.nix`),
rewrites `jj git fetch` and `jj git push -b X` to the `~/.local/bin`
wrappers inside Claude Code jj workspaces.

Mod: `on('tool.call', { tool: 'Bash' }, ...)`. Port the two regexes and
the fail-open rules verbatim, `return next({ ...e, command: rewritten })`,
and `$.ui.notice(e.tool_use_id, 'ran as jj-push ...')` so the rewrite shows
on the tool row instead of hiding in additionalContext. The regexes get
real unit tests through `claude plugin test`.

Gain: no python fork per Bash call, typed input, hot reload while
iterating, tests. Afterwards delete the script, the `jjGitRewriteHook` bin
and the PreToolUse entry.

Verify first: the worktree guard must still run after plugin `tool.call`
hooks, the way it runs after classic PreToolUse hooks. If it runs before
them, the mod cannot help and the shell hook stays.

## 2. `/sopen` and `/lopen` as registered commands (upgrade, tiny)

Today: `~/.claude/commands/sopen.md` and `lopen.md` are prompts. Each run
spends a model turn on a deterministic URL rewrite.

Mod `open-links`: `$.command.register` both in `session.start`; the
`command.run` hook rewrites the URL and calls `$.process.run(['open', url])`.
`/sopen` with no argument reads `$.ui.selection()` for the permalink, which
is the release-note line that started this. The Slack team ID moves from
the prompt text into the plugin's `userConfig` (public mod, private value).
Good first mod: no state, no UI, exercises the whole write, validate, test
loop.

## 3. Server Telegram agent: compact and clear without SSH (new, small)

Today: the `claude-agent.nix` system prompt tells the agent that slash
commands do not work over Telegram, so `/compact` or `/clear` means
attaching over SSH.

Mod `agent-selfcare`: `$.tool.register` a `compact` and a `clear` tool,
backed by `$.session.compact()` and `$.command.run`, so the model can do
them when asked over Telegram. Add a `session.measure` hook that compacts
on its own at about 85% context. Deploy: the bootstrap copies the mod
folder into the agent's writable state dir (the engine writes types beside
it and the store is read-only) and the `claude` invocation gains
`--plugin-dir <copy>`. Drop the "attach over SSH" line from the prompt.

## Not worth a mod

- `statusline-command.sh`: there is no statusline render hook. `$.ui.status`
  only adds an entry beside it.
- `hook_file_suggestion.py`: no `@`-completion event in the API.
- Worktree create/remove hooks: all jj/git shelling anyway, no gain.
- devenv SessionStart hook: the classic hook appends to `$CLAUDE_ENV_FILE`;
  a mod would have to parse the env dump into `$.env.set`. Strictly worse.
- terminal-browser, pr-walkthrough, stepwise-explainer: panes draw terminal
  elements and images, not HTML.

## Order

Item 2 first to learn the shape, then item 1 since it runs on every Bash
call, then item 3 because it needs a server deploy.

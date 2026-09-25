# Headless replacement for the `obsidian` CLI on server

Status: parked, research done, nothing built.
Date: 2026-09-25

## Trigger

The chore `claude rc` agent on server (claude-rc.nix) works inside the
Obsidian vault. The vault's root CLAUDE.md routes several operations
through the official `obsidian` CLI, which is the Obsidian.app Electron
binary in CLI mode and needs the running app with the vault open. The
server is headless and imports no graphical role, so those ops are
unavailable to it. Obsidian is closed source, so the CLI's logic cannot be
lifted; the plugin API typings and the help docs describe the semantics,
and the Mac app can serve as an oracle for tests.

Ops the CLAUDE.md sends through the CLI (everything else is plain file
tools and `bm25.py`, out of scope):

1. `move`/`rename` with wikilink rewriting
2. `delete` to `.trash/`
3. `daily:*` from `.obsidian/daily-notes.json`
4. note creation from templates, including Templater
5. `property:*` frontmatter edits
6. `task`/`tasks` checkbox listing and toggling
7. link graph: backlinks, unresolved, orphans
8. lint after write (`obsidian-linter:lint-file`)

## Verdicts

- **No single OSS tool covers ops 1 to 8.** Smallest set: `rumdl` for
  lint plus one script of our own, optionally notesmd-cli for moves.
- **Templater (op 4) is impossible headless.** Templates are JS run
  against the app API. Fallback: convert templates to core `{{date}}`-style
  tokens, or handle a small regex subset (`tp.date.now`, `tp.file.title`)
  and fail loudly on leftover `<% %>`.
- **MCP servers don't bypass this.** App-backed ones (Local REST API,
  mcp-obsidian) need the app. File-backed ones reimplement on files and
  mostly do plain moves. Unchecked: whether any file-backed MCP has a
  tested link-rewriting rename worth borrowing.
- **Xvfb hack (real Obsidian headless on server): feasible, rejected.**
  Needs GPU-disable flags, stale singleton locks after crashes,
  `obsidian restart` exits 0 so systemd won't restart it, CLI must find the
  IPC socket via DISPLAY, `"cli": true` pre-set in obsidian.json. The real
  problem is Syncthing: the server app would write `workspace.json` and
  plugin `data.json` alongside the Mac app and every plugin's on-save
  behavior would run on server too. Only worth it if exact Templater
  expansion becomes a hard requirement. One source claims the CLI needs a
  Catalyst license (unverified).

## Coverage matrix

Evidence: [src] source read, [docs] README, [unv] unverified.

| Tool | 1 move+links | 2 trash | 3 daily | 4 tmpl | 5 props | 6 tasks | 7 graph | 8 lint | nixpkgs / license / activity |
|---|---|---|---|---|---|---|---|---|---|
| notesmd-cli (ex Yakitrak obsidian-cli, Go) | partial: string replace, see risks | no, `os.Remove` [src] | partial: reads daily-notes.json, copies template verbatim, tries `obsidian://` unless `--editor` [src] | no | yes [docs] | no | no | no | not packaged; MIT; v0.3.7 2026-09-01 |
| iwe (Rust CLI+LSP) | partial: parse-tree rename of `[[x]]`, `[[x\|a]]`, md links; embeds/`#heading`/basename resolution [unv]; reformats touched files [docs] | no (`delete` strips refs) | no | own templates | schema only | no | partial (`stats` broken links) | own normalizer | 0.19.1 in nixpkgs (upstream 0.24.2); Apache-2.0 |
| zk | no rename (request closed) | no | own system | Handlebars | no | no | yes, needs own index | no | 0.15.6; GPL-3.0 |
| marksman | LSP rename; aliases/embeds/folders undocumented | no | no | no | no | no | LSP refs | no | in nixpkgs; MIT |
| markdown-oxide | LSP, Obsidian-oriented; rename [unv] | no | editor cmd | no | no | no | LSP refs | no | 0.25.12 in nixpkgs |
| obsidiantools (Python) | no, read-only | no | no | no | reads | no | yes: backlinks, orphans, missing | no | not packaged; last commit 2025-07 |
| obsidian-export | no | no | no | no | no | no | no | no | in nixpkgs |
| markdown-link-check | no, md/HTTP only | no | no | no | no | no | no | no | in nixpkgs |
| rumdl (`flavor = obsidian`) | no | no | no | no | no | no | no | partial: markdownlint rules + `--fix`, knows wikilinks/callouts/Templater/Dataview | 0.2.73 in nixpkgs; MIT; active |
| markdownlint-cli2 / remark | no | no | no | no | remark parses | no | no | partial, trips on Obsidian syntax | markdownlint in nixpkgs |
| Local REST API, mcp-obsidian, official CLI | all | | | | | | | | rejected: need running app |

obsidian-linter has no headless mode; maintainer closed the CLI request
(#987). rumdl covers markdown hygiene but not the linter's YAML rules
(key sort, timestamps, tag/alias formatting).

## notesmd-cli rename risks [src, `pkg/obsidian/utils.go`]

About 40 lines of `bytes.ReplaceAll`. Case-sensitive; rewrites inside code
blocks; duplicate basenames rewrite the wrong note's links; misses
`[[Note.md]]`, `../` relative and `%20` md links; walks `.trash/`; no
dry-run. Mostly fine for ~600 root notes with unique names, but better to
own this piece.

## Recommended build

- `rumdl` for op 8.
- One Python script (`python-frontmatter`, both in nixpkgs, ~250 lines):
  - **mv:** move, then rewrite `[[old]]`, `[[old|`, `[[old#`, `[[old^`,
    `![[...]]`, `[[old.md]]` and md links incl. `%20` and relative paths.
    Case-insensitive like Obsidian; skip fenced and inline code, `.obsidian/`
    and `.trash/`; refuse on ambiguous old basename or new-name collision;
    `--dry-run` with diff; write full path only when the basename stops
    being unique (Obsidian "shortest path").
  - **trash:** move into `.trash/`.
  - **daily:** read daily-notes.json, convert the Moment format, expand
    core tokens.
  - **template:** core `{{title}}`, `{{date[:fmt]}}`, `{{time}}` plus regex
    for `tp.date.now("…")`, `tp.file.title`, `tp.file.creation_date`; fail on
    leftover `<% %>`.
  - **props:** set/remove preserving key order.
  - **tasks:** list/toggle `- [ ]` by file and line; append `✅ YYYY-MM-DD`
    for Tasks-plugin style.
  - **graph:** single-pass link index for backlinks, unresolved, orphans.
- Fidelity test: run the same rename through the real CLI on the Mac on a
  vault copy and diff. Fixtures: duplicate basenames, aliases, heading and
  block links, embeds, links inside code fences.
- Then give the vault CLAUDE.md a headless branch (or override in
  `chore/CLAUDE.md`) pointing the server agent at the script.

## Sources

- notesmd-cli: https://github.com/Yakitrak/notesmd-cli (src `pkg/obsidian/utils.go`, `note.go`, `pkg/actions/daily.go`, `delete.go`)
- iwe: https://iwe.md/docs/cli/ ; https://github.com/iwe-org/iwe/blob/master/docs/cli-rename.md ; https://github.com/iwe-org/iwe/blob/master/docs/comparison.md
- zk: https://github.com/zk-org/zk/issues/200 ; https://github.com/zk-org/zk/blob/main/CHANGELOG.md
- marksman: https://github.com/artempyanykh/marksman/blob/main/docs/features.md
- markdown-oxide: https://github.com/Feel-ix-343/markdown-oxide
- obsidiantools: https://github.com/mfarragher/obsidiantools
- obsidian-export: https://github.com/zoni/obsidian-export
- markdown-link-check: https://github.com/tcort/markdown-link-check
- obsidian-linter CLI request: https://github.com/platers/obsidian-linter/issues/987
- rumdl: https://github.com/rvben/rumdl ; https://github.com/rvben/rumdl/blob/main/docs/flavors.md
- mcp-obsidian (REST API): https://github.com/MarkusPfundstein/mcp-obsidian
- Templater: https://silentvoid13.github.io/Templater/
- Xvfb: https://forum.obsidian.md/t/running-obsidian-headlessly-on-ubuntu-for-ai-agent-workflows-xvfb-systemd-setup/112741 ; https://github.com/lucastraba/obsidianless ; https://rup12.net/posts/running-obsidian-headless/
- Obsidian Headless (official, Sync only): https://obsidian.md/help/headless
- nixpkgs versions via local `nix eval nixpkgs#<pkg>.version`

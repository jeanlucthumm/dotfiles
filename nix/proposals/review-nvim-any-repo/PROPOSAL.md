# review-nvim for non-jj checkouts

Status: parked idea, not started.
Date: 2026-09-25

## Trigger

While wiring the chore `claude rc` agent (claude-rc.nix, syncthing.nix,
server.nix, plus a settings file in the Obsidian vault), we wanted a human
review pass in Neovide via `/review-nvim` and could not: the change set was
uncommitted edits in a yadm-tracked tree, not a jj workspace.

## What blocks it today

The `review.nvim` plugin (our fork) is repo-agnostic. Its workspace mode
diffs `$REVIEW_BASE` against the working tree with plain git, so the file
on disk is the new side and LSP works. Nothing in the plugin needs jj.

Every jj assumption lives in the wrapper script
`autoimport/packages/_derivations/review-pr.nix`, and the `/review-nvim`
skill only knows how to call that script:

- Resolves the target as a jj workspace (`.jj` dir or a name under
  `<repo>/.claude/worktrees/`) and refuses anything else.
- Needs a colocated `.git` next to the main checkout for the git shim.
- Resolves tip and base with `jj log` revsets (`@`, `@-`, `trunk()`).
- Builds a throwaway index from the tip commit so `git diff <base>` lists
  added files.

## Sketch

Add a second front door to `review-pr` for "review what is dirty in this
git checkout", keeping the jj path untouched:

- Target is any directory inside a git worktree. For yadm, accept a
  `--yadm` flag (or detect `yadm rev-parse --git-dir`) and set `GIT_DIR`
  to `~/.local/share/yadm/repo.git` with `GIT_WORK_TREE=$HOME`.
- Base defaults to `HEAD`; new side is the working tree, same contract as
  today (`REVIEW_BASE`, `REVIEW_SESSION_KEY`, `REVIEW_EXPORT_FILE`,
  `REVIEW_QUIT_ON_CLOSE`).
- Throwaway index from `HEAD`, then `git add -N` the untracked files under
  the target directory so new files show up. Scope the add to the target
  path: on yadm the worktree is `$HOME`, and `git add -A` there would be
  catastrophic.
- Session key from the target path, since there is no workspace name.
- Skill step 1 gains a branch: if the cwd is not a jj repo, pass the
  directory instead of a workspace name.

## Open questions

- A change set that spans two repos (this case: nix repo plus the vault)
  is still two reviews. Fine for now; note it in the skill so the agent
  launches both rather than silently reviewing one.
- Whether to keep `review-pr` as one script with two modes or split into
  `review-pr` and `review-dirty`. One script keeps the nvim contract in one
  place, which is the part that actually bit us before (see the
  `nvim-review-flow` gotchas the skill references).

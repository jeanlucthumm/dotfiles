#!/bin/bash
# Global WorktreeCreate hook: jj workspaces for any jj-colocated repo.
#
# Claude Code's native EnterWorktree uses `git worktree`, which is wrong for
# jj repos (moving @ in a colocated checkout from a git worktree corrupts the
# jj working copy's view of it). This hook makes EnterWorktree create a jj
# workspace under <repo>/.claude/worktrees/ instead.
#
# Delegation: if the repo carries its own .claude/hooks/setup-worktree.sh
# (e.g. repl-it-web, which layers NX socket-dir and nix-env quirks on top),
# that script is exec'd verbatim and owns the whole job. The generic logic
# below runs only for repos without one.
#
# jj-only by design: every repo on this machine is jj-colocated. A non-jj
# repo fails loudly rather than falling back to git worktrees.
set -euo pipefail

INPUT=$(cat)
NAME=$(echo "$INPUT" | jq -r '.name // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd')
if [ -z "$NAME" ]; then
  NAME=$(basename "$(echo "$INPUT" | jq -r '.worktree_path // empty')")
fi
BASE_REF=$(echo "$INPUT" | jq -r '.base_ref // empty')

# Anchor at the main checkout even when invoked from inside a workspace
# (e.g. a subagent with worktree isolation): nesting workspaces fails.
case "$CWD" in
  */.claude/worktrees/*) CWD="${CWD%%/.claude/worktrees/*}" ;;
esac

# Walk up to the jj repo root: the session cwd may be a subdirectory.
REPO="$CWD"
while [ "$REPO" != "/" ] && [ ! -d "$REPO/.jj" ]; do
  REPO=$(dirname "$REPO")
done
if [ ! -d "$REPO/.jj" ]; then
  echo "worktree-create: no jj repo found at or above $CWD." >&2
  echo "This machine's worktree hook only handles jj-colocated repos (jj git init --colocate)." >&2
  exit 1
fi

# Repo-local hook wins outright: it owns quirks this generic script can't know.
if [ -x "$REPO/.claude/hooks/setup-worktree.sh" ]; then
  exec "$REPO/.claude/hooks/setup-worktree.sh" <<<"$INPUT"
fi

WORKTREE_PATH="${REPO}/.claude/worktrees/${NAME}"
mkdir -p "$(dirname "$WORKTREE_PATH")"

# Reuse an existing workspace of the same name instead of failing on
# `jj workspace add`. EnterWorktree's `path` parameter validates against
# `git worktree list` and so can never re-enter a jj workspace; re-entry
# works by passing the same `name` and landing in this branch. base_ref is
# ignored on reuse -- the workspace stays on whatever it was left at.
# (grep without -q: with pipefail, -q's early exit SIGPIPEs jj and fails the pipeline)
if [ -d "$WORKTREE_PATH" ] && jj -R "$REPO" workspace list --ignore-working-copy 2>/dev/null | grep "^${NAME}:" >/dev/null; then
  echo "Reusing existing jj workspace $NAME at $WORKTREE_PATH" >&2
  echo "$WORKTREE_PATH"
  exit 0
fi

# Base the workspace on the requested ref if jj can resolve it, else trunk().
REV='trunk()'
if [ -n "$BASE_REF" ] && jj -R "$REPO" log --no-graph --ignore-working-copy -r "$BASE_REF" -T 'commit_id' >/dev/null 2>&1; then
  REV="$BASE_REF"
fi

echo "Creating jj workspace $NAME at $WORKTREE_PATH (base: $REV)..." >&2
jj -R "$REPO" workspace add --name "$NAME" -r "$REV" "$WORKTREE_PATH" >&2

# Give the workspace its own (dummy) git identity: Claude Code verifies a
# worktree's git identity on EnterWorktree and refuses a directory whose git
# resolves to the parent checkout. An empty repo here satisfies that check,
# and any real git invocation inside the workspace hits the inert dummy repo,
# never the main checkout. jj ignores .git entirely.
git init -q "$WORKTREE_PATH"

# Personal gitignored files every workspace needs. This replaces .worktreeinclude,
# which Claude Code does not process when a WorktreeCreate hook is configured.
for f in .env .claude/settings.local.json CLAUDE.local.md .claude/hooks; do
  if [ -e "$REPO/$f" ]; then
    mkdir -p "$WORKTREE_PATH/$(dirname "$f")"
    cp -R "$REPO/$f" "$WORKTREE_PATH/$f"
  fi
done

# Optional repo-local extension for post-setup tweaks that don't warrant a
# full setup-worktree.sh override. Env contract: REPO, WORKTREE_PATH, NAME.
if [ -x "$REPO/.claude/hooks/worktree-setup.local.sh" ]; then
  REPO="$REPO" WORKTREE_PATH="$WORKTREE_PATH" NAME="$NAME" \
    "$REPO/.claude/hooks/worktree-setup.local.sh" >&2
fi

echo "$WORKTREE_PATH"

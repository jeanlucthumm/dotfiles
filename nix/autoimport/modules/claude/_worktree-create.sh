# shellcheck shell=bash
# WorktreeCreate hook (installed by claude-code.nix as claude-worktree-create):
# jj workspaces for any jj-colocated repo.
#
# Claude Code's native EnterWorktree runs plain `git worktree add`, which jj
# knows nothing about. This hook makes EnterWorktree (and isolated subagents)
# create a jj workspace under <repo>/.claude/worktrees/ instead; jj itself
# attaches a real linked Git worktree, so the workspace has its own git
# identity with HEAD tracking the workspace's @-.
#
# Delegation: a repo carrying its own .claude/hooks/setup-worktree.sh has it
# exec'd verbatim, owning the whole job. A repo carrying
# .claude/hooks/worktree-setup.local.sh gets it run after the generic setup
# below for repo-specific extras.
#
# jj-only by design: every repo on this machine is jj-colocated. A non-jj
# repo fails loudly rather than falling back to plain git worktrees.

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

# Hand the repo-local hook a cwd that already is the repo root: it derives the
# workspace path from .cwd verbatim, so a session started in a subdirectory
# would otherwise get its workspace nested under that subdirectory.
INPUT=$(jq --arg c "$REPO" '.cwd = $c' <<<"$INPUT")

# Repo-local hook wins outright: it owns quirks this generic script can't know.
if [ -x "$REPO/.claude/hooks/setup-worktree.sh" ]; then
  exec "$REPO/.claude/hooks/setup-worktree.sh" <<<"$INPUT"
fi

WORKTREE_PATH="${REPO}/.claude/worktrees/${NAME}"
mkdir -p "$(dirname "$WORKTREE_PATH")"

# Reuse an existing workspace of the same name instead of failing on
# `jj workspace add`: EnterWorktree re-entry by `name` lands here. base_ref is
# ignored on reuse; the workspace stays on whatever it was left at.
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
# --colocate states the requirement instead of leaning on jj's default (which
# follows the git.colocate setting): Claude Code refuses a worktree without
# its own git identity.
jj -R "$REPO" workspace add --colocate --name "$NAME" -r "$REV" "$WORKTREE_PATH" >&2

# Personal gitignored files every workspace needs. This replaces .worktreeinclude,
# which Claude Code does not process when a WorktreeCreate hook is configured.
# Some of these are tracked in some repos (dotfiles tracks .claude/hooks), so
# the target may already exist. Copying into the PARENT merges a directory
# into an existing one and -n keeps tracked files; naming the target itself
# would nest a copy inside it (`cp -R dir existing-dir` -> dir/dir).
for f in .env .claude/settings.local.json CLAUDE.local.md .claude/hooks; do
  if [ -e "$REPO/$f" ]; then
    mkdir -p "$WORKTREE_PATH/$(dirname "$f")"
    cp -Rn "$REPO/$f" "$WORKTREE_PATH/$(dirname "$f")/"
  fi
done

# Optional repo-local extension for post-setup tweaks that don't warrant a
# full setup-worktree.sh override. Env contract: REPO, WORKTREE_PATH, NAME.
if [ -x "$REPO/.claude/hooks/worktree-setup.local.sh" ]; then
  export REPO WORKTREE_PATH NAME
  "$REPO/.claude/hooks/worktree-setup.local.sh" >&2
fi

echo "$WORKTREE_PATH"

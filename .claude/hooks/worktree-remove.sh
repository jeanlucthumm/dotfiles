#!/bin/bash
# Global WorktreeRemove hook: counterpart of worktree-create.sh.
# Delegates to the repo's own .claude/hooks/remove-worktree.sh when present;
# otherwise forgets the jj workspace and deletes the directory.
set -euo pipefail

INPUT=$(cat)
WORKTREE_PATH=$(echo "$INPUT" | jq -r '.worktree_path // empty')
[ -z "$WORKTREE_PATH" ] && exit 0

case "$WORKTREE_PATH" in
  */.claude/worktrees/*) ;;
  *)
    echo "refusing to remove $WORKTREE_PATH (not under .claude/worktrees)" >&2
    exit 0
    ;;
esac

MAIN_REPO="${WORKTREE_PATH%/.claude/worktrees/*}"

if [ -x "$MAIN_REPO/.claude/hooks/remove-worktree.sh" ]; then
  exec "$MAIN_REPO/.claude/hooks/remove-worktree.sh" <<<"$INPUT"
fi

NAME=$(basename "$WORKTREE_PATH")
jj -R "$MAIN_REPO" workspace forget "$NAME" >&2 || true
# A bootstrapped worktree can hold hundreds of thousands of files (package
# manager hardlinks), so deleting it in-line can blow the hook timeout: the
# harness then reports the hook failed even though the orphaned rm finishes
# later. Instead, rename the worktree into a trash dir (instant, frees the
# path for name reuse) and delete in a detached background process.
TRASH_DIR="$MAIN_REPO/.claude/worktree-trash"
mkdir -p "$TRASH_DIR"
TRASH_PATH="$TRASH_DIR/$NAME-$$-$(date +%s)"
if mv "$WORKTREE_PATH" "$TRASH_PATH" 2>/dev/null; then
  nohup rm -rf "$TRASH_PATH" >/dev/null 2>&1 &
else
  rm -rf "$WORKTREE_PATH"
fi
echo "Removed jj workspace $NAME" >&2

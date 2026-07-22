{
  lib,
  writeShellApplication,
  git,
  coreutils,
}:
writeShellApplication {
  name = "review-pr";

  # jj, nvim, and neovide are intentionally resolved from the user's PATH so
  # the review runs with the same versions as the surrounding environment (jj
  # working-copy formats can differ across versions). git is only used for
  # read-only plumbing (merge-base, read-tree) against the colocated store.
  runtimeInputs = [git coreutils];

  text = ''
    usage() {
      cat >&2 <<'EOF'
    Usage: review-pr [--spawn|--headless] <workspace-name-or-path>

    LSP-enabled nvim code review of a jj workspace's PR commit: diffs the
    working tree against the merge-base with trunk using review.nvim's
    workspace mode. When the editor closes, prints the review comments
    (REVIEW.md) to stdout for agent handoff.

    Modes:
      (default)   run nvim in the current terminal
      --spawn     open a Neovide window; block until it closes
      --headless  run nvim headless (for tests; drive via the socket)

    The nvim instance listens on /tmp/review-pr-<name>.sock for remote
    control (nvim --server <sock> --remote-send/--remote-expr).
    EOF
      exit 2
    }

    mode=terminal
    ws_arg=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --spawn) mode=spawn; shift ;;
        --headless) mode=headless; shift ;;
        -h|--help) usage ;;
        -*) echo "review-pr: unknown flag: $1" >&2; usage ;;
        *) ws_arg="$1"; shift ;;
      esac
    done
    [[ -n "$ws_arg" ]] || usage

    # Resolve the workspace directory: either a path to a jj workspace, or a
    # workspace name under <repo>/.claude/worktrees/ relative to the current
    # jj repo.
    if [[ -e "$ws_arg/.jj" ]]; then
      ws_dir=$(realpath "$ws_arg")
      ws_name=$(basename "$ws_dir")
    else
      repo_root=$(jj root --ignore-working-copy 2>/dev/null) || {
        echo "review-pr: '$ws_arg' is not a workspace dir and cwd is not in a jj repo" >&2
        exit 1
      }
      ws_name="$ws_arg"
      ws_dir="$repo_root/.claude/worktrees/$ws_name"
      if [[ ! -e "$ws_dir/.jj" ]]; then
        echo "review-pr: no jj workspace at $ws_dir" >&2
        exit 1
      fi
    fi

    # Find the main checkout (owner of the shared commit store). In a jj
    # workspace, .jj/repo is a file whose content is a path (usually
    # relative to <ws>/.jj) pointing at the main checkout's .jj/repo.
    if [[ -f "$ws_dir/.jj/repo" ]]; then
      ptr=$(<"$ws_dir/.jj/repo")
      if [[ "$ptr" = /* ]]; then
        main_jj_repo=$(realpath "$ptr")
      else
        main_jj_repo=$(realpath "$ws_dir/.jj/$ptr")
      fi
      main_root=$(dirname "$(dirname "$main_jj_repo")")
    else
      main_root="$ws_dir" # this is the main checkout itself
    fi
    git_dir="$main_root/.git"
    if [[ ! -e "$git_dir" ]]; then
      echo "review-pr: $main_root is not git-colocated (no .git); cannot set up the git shim" >&2
      exit 1
    fi

    # Snapshot the workspace so @ reflects the files on disk, then resolve
    # the tip and the base (merge-base of tip and trunk).
    jj -R "$ws_dir" status >/dev/null
    tip=$(jj -R "$ws_dir" log --ignore-working-copy --no-graph -r @ -T 'commit_id')
    trunk=$(jj -R "$ws_dir" log --ignore-working-copy --no-graph -r 'trunk()' -T 'commit_id')
    base=$(git --git-dir "$git_dir" merge-base "$tip" "$trunk")

    # Git shim: make git treat the workspace as a clean checkout of tip, even
    # though the workspace has no .git. The throwaway index (populated from
    # tip) makes `git diff <base>` list every PR change, including added
    # files, without ever touching the main checkout's index.
    idx=$(mktemp "''${TMPDIR:-/tmp}/review-pr-index.XXXXXX")
    trap 'rm -f "$idx"' EXIT
    export GIT_DIR="$git_dir"
    export GIT_WORK_TREE="$ws_dir"
    export GIT_INDEX_FILE="$idx"
    unset GIT_CEILING_DIRECTORIES
    git read-tree "$tip"

    # Contract with review.nvim's workspace mode. This nvim exists solely for
    # the review, so closing it should quit (the process wait is the handoff).
    # The export file deliberately lives OUTSIDE the workspace: jj would
    # auto-snapshot a workspace-resident file straight into the PR commit.
    export REVIEW_BASE="$base"
    export REVIEW_SESSION_KEY="$ws_name"
    export REVIEW_EXPORT_FILE="''${TMPDIR:-/tmp}/review-pr-$ws_name.md"
    export REVIEW_QUIT_ON_CLOSE=1

    socket="/tmp/review-pr-$ws_name.sock"
    rm -f "$socket" "$REVIEW_EXPORT_FILE"

    {
      echo "review-pr: workspace=$ws_name dir=$ws_dir"
      echo "review-pr: tip=$tip"
      echo "review-pr: base=$base (merge-base with trunk)"
      echo "review-pr: socket=$socket"
    } >&2

    cd "$ws_dir"
    case "$mode" in
      terminal)
        nvim --listen "$socket" "+Review workspace"
        ;;
      headless)
        nvim --headless --listen "$socket" "+Review workspace"
        ;;
      spawn)
        if ! command -v neovide >/dev/null; then
          echo "review-pr: neovide not found on PATH" >&2
          exit 1
        fi
        neovide --no-fork -- --listen "$socket" "+Review workspace"
        ;;
    esac

    if [[ -f "$REVIEW_EXPORT_FILE" ]]; then
      echo "=== Review comments ($ws_name) ==="
      cat "$REVIEW_EXPORT_FILE"
    else
      echo "review-pr: editor closed without completing a review (no $REVIEW_EXPORT_FILE)" >&2
      exit 1
    fi
  '';

  meta = {
    description = "LSP-enabled nvim code review of a jj workspace PR commit, with agent handoff export";
    platforms = lib.platforms.unix;
  };
}

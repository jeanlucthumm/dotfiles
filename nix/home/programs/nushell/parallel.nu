# Parallel worktree utilities

def worktree [] {}

# Create parallel worktrees and run a command in each via tmux
def "worktree parallel" [
  count: int,    # Number of parallel worktrees to create
  ...cmd: string # Command to run in each worktree
]: [nothing -> nothing] {
  if ($cmd | is-empty) {
    error make -u { msg: "Command is required" }
  }

  let current_branch = git branch --show-current | str trim
  if ($current_branch | is-empty) {
    error make -u { msg: "Not on a branch" }
  }

  if $count <= 0 {
    error make -u { msg: "Count must be greater than 0" }
  }

  let git_root = git rev-parse --show-toplevel | str trim
  let session = $current_branch | str replace --all '/' '-'

  # Validate all worktrees can be created
  let plans = 1..$count | each { |i|
    let new_branch = $"($current_branch)-($i)"
    let dir_name = $new_branch | split row '/' | last
    let worktree_path = $git_root | path dirname | path join $dir_name

    if (git branch --list $new_branch | str trim | is-not-empty) {
      error make -u { msg: $"Branch already exists: ($new_branch)" }
    }
    if ($worktree_path | path exists) {
      error make -u { msg: $"Path already exists: ($worktree_path)" }
    }

    { branch: $new_branch, dir_name: $dir_name, path: $worktree_path }
  }

  # Create all worktrees
  for plan in $plans {
    git worktree add -b $plan.branch $plan.path
    print $"Created worktree: ($plan.path)"
  }

  let shell_cmd = $cmd | str join ' '

  # Create tmux session and windows
  let first = $plans | first
  let rest = $plans | skip 1

  ^tmux new-session -d -s $session -n $first.dir_name -c $first.path $shell_cmd

  for plan in $rest {
    ^tmux new-window -t $"($session):" -n $plan.dir_name -c $plan.path $shell_cmd
  }

  print ""
  print $"Created tmux session '($session)' with ($count) windows"
  print $"Attach with: tmux attach -t '($session)'"
}

# Run parallel Claude Code instances working on PR.md
def "worktree claude" [
  count: int  # Number of parallel worktrees/claude instances
]: [nothing -> nothing] {
  if not ("PR.md" | path exists) {
    error make -u { msg: "PR.md not found in current directory" }
  }

  let prompt = "Read PR.md for your implementation task.

IMPORTANT - You are running autonomously while the user is AFK:
- Work end-to-end without asking questions - make reasonable decisions
- If something is ambiguous, pick the simplest reasonable interpretation
- Commit your changes when done with a clear commit message
- If you hit a blocker you truly cannot resolve, document it in a BLOCKER.md file and stop"

  worktree parallel $count $"claude -- r#'($prompt)'#"
}

# Clean up parallel worktrees created by worktree parallel/claude
def "worktree cleanup" []: [nothing -> nothing] {
  let current_branch = git branch --show-current | str trim
  if ($current_branch | is-empty) {
    error make -u { msg: "Not on a branch" }
  }

  let session = $current_branch | str replace --all '/' '-'

  # Find all parallel worktrees (current-branch-1, current-branch-2, etc.)
  let parallel_worktrees = ngit worktree list
    | where { |w| $w.branch =~ $"^($current_branch)-\\d+$" }

  if ($parallel_worktrees | is-empty) {
    print "No parallel worktrees found to clean up"
    return
  }

  print $"Found parallel worktrees: ($parallel_worktrees | get branch | str join ', ')"

  # Kill tmux session if it exists
  try {
    ^tmux kill-session -t $session
    print $"Killed tmux session: ($session)"
  } catch { }

  # Remove worktrees and delete branches
  for wt in $parallel_worktrees {
    git worktree remove --force $wt.path
    print $"Removed worktree: ($wt.path)"

    git branch -D $wt.branch
    print $"Deleted branch: ($wt.branch)"
  }

  print "Cleanup complete"
}

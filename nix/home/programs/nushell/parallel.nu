# Parallel worktree utilities

def worktree [] {}

# Create parallel worktrees and run a command in each via tmux
def "worktree parallel" [
  count: int,      # Number of parallel worktrees to create
  --subdir: string # Subdirectory within worktree to run command in
  ...cmd: string   # Command to run in each worktree
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
    let work_dir = if ($subdir | is-empty) { $worktree_path } else { $worktree_path | path join $subdir }

    if (git branch --list $new_branch | str trim | is-not-empty) {
      error make -u { msg: $"Branch already exists: ($new_branch)" }
    }
    if ($worktree_path | path exists) {
      error make -u { msg: $"Path already exists: ($worktree_path)" }
    }

    { branch: $new_branch, dir_name: $dir_name, path: $worktree_path, work_dir: $work_dir }
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

  ^tmux new-session -d -s $session -n $first.dir_name -c $first.work_dir $shell_cmd
  sleep 100ms

  for plan in $rest {
    ^tmux new-window -t $"($session):" -n $plan.dir_name -c $plan.work_dir $shell_cmd
    sleep 100ms
  }

  print ""
  print $"Created tmux session '($session)' with ($count) windows"
  print $"Attach with: tmux attach -t '($session)'"
}

# Run parallel Claude Code instances working on PR.md
def "worktree claude" [
  count: int         # Number of parallel worktrees/claude instances
  --subdir: string   # Subdirectory within worktree to run in
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

  let cmd = $"claude --permission-mode acceptEdits -- r#'($prompt)'#"
  if ($subdir | is-empty) {
    worktree parallel $count $cmd
  } else {
    worktree parallel $count --subdir $subdir $cmd
  }
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

# Extract diffs from all parallel branches
def "worktree diffs" []: [nothing -> table<id: int, branch: string, diff: string>] {
  let branch = git branch --show-current | str trim
  if ($branch | is-empty) {
    error make -u { msg: "Not on a branch" }
  }

  let wts = ngit worktree list | where { |w| $w.branch =~ $"^($branch)-\\d+$" }
  if ($wts | is-empty) {
    error make -u { msg: "No parallel branches found" }
  }

  let base = git merge-base $branch ($wts | first | get branch) | str trim

  $wts | each { |wt|
    {
      id: ($wt.branch | split row '-' | last | into int),
      branch: $wt.branch,
      diff: (git diff $"($base)...($wt.branch)")
    }
  }
}

# Judge a match between two implementations
def judge_match [a: record, b: record, spec: string, out_file: string, round_dir: string, tourney_dir: string]: [nothing -> record] {
  let prompt = $"You are judging two implementations of the same task.

## Task
($spec)

## Implementation A \(branch: ($a.branch)\)
```diff
($a.diff)
```

## Implementation B \(branch: ($b.branch)\)
```diff
($b.diff)
```

## Criteria
1. Correctness: Does it fulfill the requirements?
2. Code quality: Is it clean and maintainable?
3. Minimalism: Does it avoid unnecessary changes?

## Instructions
1. Write your detailed analysis and reasoning to: ($out_file)
2. If the LOSING implementation has good ideas the winner lacks, write them to:
   ($round_dir)/<loser-branch>_insights.md
   Format: bullet points of actionable insights. Don't force it - skip if nothing valuable.
3. End your response with exactly: WINNER: A or WINNER: B"

  let out = $prompt | ^claude -p --allowed-tools "Write" --add-dir $tourney_dir --permission-mode acceptEdits --no-session-persistence

  # Parse "WINNER: A" or "WINNER: B" from output
  let winner_lines = $out | lines | where { $in =~ "^WINNER:" }
  if ($winner_lines | is-empty) {
    print "  Warning: Could not parse winner, picking randomly"
    return ([$a $b] | shuffle | first)
  }
  let winner = $winner_lines | last
  if ($winner | str contains "A") { $a } else { $b }
}

# Run bracket-style tournament on parallel implementations
def "worktree tournament" []: [nothing -> record<winner: string, dir: string>] {
  if not ("PR.md" | path exists) {
    error make -u { msg: "PR.md not found in current directory" }
  }
  let spec = open PR.md

  # Filter to non-empty diffs
  let subs = worktree diffs | where { $in.diff | str trim | is-not-empty }
  if ($subs | is-empty) {
    error make -u { msg: "No valid submissions (all diffs empty)" }
  }
  if ($subs | length) == 1 {
    print $"Only one submission: (($subs | first).branch) auto-wins"
    return { winner: ($subs | first).branch, dir: "" }
  }

  print $"Starting tournament with ($subs | length) submissions"

  let session = git branch --show-current | str trim | str replace --all '/' '-'
  let dir = $"/tmp/tournament-($session)"
  mkdir $dir

  mut remaining = $subs | shuffle
  mut round = 1

  while ($remaining | length) > 1 {
    print $"=== Round ($round) \(($remaining | length) left\) ==="
    let round_dir = $"($dir)/round-($round)"
    mkdir $round_dir

    $remaining = ($remaining | chunks 2 | par-each { |pair|
      if ($pair | length) == 1 {
        print $"  ($pair.0.branch) gets bye"
        $pair | first
      } else {
        let out_file = $"($round_dir)/($pair.0.branch)_vs_($pair.1.branch).md"
        let winner = judge_match $pair.0 $pair.1 $spec $out_file $round_dir $dir
        print $"  ($pair.0.branch) vs ($pair.1.branch) → ($winner.branch)"
        $winner
      }
    })
    $round = $round + 1
  }

  let winner = $remaining | first
  $winner.branch | save -f $"($dir)/winner.txt"

  # Consolidate insights from all rounds
  let insight_files = glob $"($dir)/round-*/*_insights.md"
  if ($insight_files | is-not-empty) {
    let insights = $insight_files | each { open $in } | str join "\n\n"
    $"# Insights from Eliminated Implementations\n\n($insights)" | save -f $"($dir)/insights.md"
    print $"\nInsights collected: ($dir)/insights.md"
  }

  print $"\nTournament complete! Winner: ($winner.branch)"
  print $"Results: ($dir)"

  { winner: $winner.branch, dir: $dir }
}

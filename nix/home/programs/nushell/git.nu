# Nushell wrapper for git
def ngit [] {}

# Nushell version of git branch
def "ngit branch" []: [nothing -> table<symbol: string, branch: string>] {
  git branch |
    lines |
    parse "{symbol} {branch}" |
    str trim
}

# Nushell wrapper for git worktree
def "ngit worktree" [] {}

# Nushell version of git worktree list
def "ngit worktree list" []: [nothing -> table<path: string, commit: string, branch: string>] {
  git worktree list | lines | parse "{path} {commit} [{branch}]" | str trim
}

# Git status
def "ngit status" []: [nothing -> table<status: string, file: string>] {
  git status --porcelain | from ssv -m 1 -n | rename status file
}

# Create PR context for LLMs
def "ngit prcontext" [
  revrange: string # Revision range this applies to e.g. `master..HEAD`
  ticket_title: string # Title of the ticket of this PR
  ticket_desc: string # Description fo the ticket of this PR
]: [nothing -> string] {
  $"(git diff $revrange | label-diff)

  <commit_messages>
  (git log $revrange --oneline)
  </commit_messages>

  <ticket>
  Title: ($ticket_title)
  Description: ($ticket_desc)
  </ticket>
  "
}

# Ensure a tmux session exists and open a window in the given directory
def tmux-window [
  session: string,
  window: string,
  dir: string,
  cmd?: string,
]: [nothing -> nothing] {
  let created = (try {
    ^tmux has-session -t $session err> /dev/null out> /dev/null
    false
  } catch {
    if ($cmd == null) {
      ^tmux new-session -d -s $session -n $window -c $dir
    } else {
      ^tmux new-session -d -s $session -n $window -c $dir $cmd
    }
    true
  })

  if not $created {
    if ($cmd == null) {
      ^tmux new-window -t $session -n $window -c $dir
    } else {
      ^tmux new-window -t $session -n $window -c $dir $cmd
    }
  }
}

# Nushell worktree helpers
def worktree [] {}

def "worktree parallel" [
  count: int,      # Number of parallel worktrees to create
  cmd?: string,    # Optional tmux command to run in each window (e.g., 'nvim .; exec $SHELL')
]: [nothing -> nothing] {
  # Ensure we are on a branch inside a git worktree
  let current_branch = (git branch --show-current | str trim)
  if ($current_branch | is-empty) {
    error make -u { msg: "Not on a branch" }
  }

  if $count <= 0 {
    error make -u { msg: "Count must be greater than 0" }
  }

  let git_root = (git rev-parse --show-toplevel | str trim)

  # First, compute and validate all target worktrees
  let plans = (1..$count
    | each { |i|
        let new_branch = $'($current_branch)-($i)'
        let dir_name = ($new_branch | split row '/' | last)
        let worktree_path = ($git_root | path dirname | path join $dir_name)

        let branch_exists = (git branch --list $new_branch | str trim | is-not-empty)
        if $branch_exists {
          error make -u { msg: $'Branch already exists: ($new_branch)' }
        }

        if ($worktree_path | path exists) {
          error make -u { msg: $'Path already exists: ($worktree_path)' }
        }

        { branch: $new_branch, dir_name: $dir_name, path: $worktree_path }
      })

  # Create all worktrees
  for plan in $plans {
    git worktree add -b $plan.branch $plan.path
    print $'Created worktree: ($plan.path) for branch: ($plan.branch)'
  }

  # After all worktrees are created, open tmux windows in a session named after the current branch
  for plan in $plans {
    tmux-window $current_branch $plan.dir_name $plan.path $cmd
  }

  # Confirm tmux session status
  try {
    ^tmux has-session -t $current_branch err> /dev/null out> /dev/null
    print $"tmux session '($current_branch)' created. Attach with: tmux attach -t '($current_branch)'"
  } catch {
    print $"Warning: tmux session for '($current_branch)' not found; windows may not have been created."
  }
}

# Create a new worktree next to the repo with branch "<current>2"
def "worktree 2" []: [nothing -> nothing] {
  # Ensure we are on a branch inside a git worktree
  let current_branch = (git branch --show-current | str trim)
  if ($current_branch | is-empty) {
    error make -u { msg: "Not on a branch" }
  }

  let git_root = (git rev-parse --show-toplevel | str trim)

  # New branch name and destination path
  let new_branch = $'($current_branch)2'
  let dir_name = ($new_branch | split row '/' | last)
  let worktree_path = ($git_root | path dirname | path join $dir_name)

  # Safety checks
  let branch_exists = (git branch --list $new_branch | str trim | is-not-empty)
  if $branch_exists {
    error make -u { msg: $'Branch already exists: ($new_branch)' }
  }

  if ($worktree_path | path exists) {
    error make -u { msg: $'Path already exists: ($worktree_path)' }
  }

  # Create the worktree and the new branch from current HEAD
  git worktree add -b $new_branch $worktree_path
  print $'Created worktree: ($worktree_path) for branch: ($new_branch)'

  # Open new kitty tab with the work tree name (macOS only)
  if ($nu.os-info.name == "macos") {
    kitten @ launch --type=tab --tab-title $dir_name --cwd $worktree_path
  }
}

# Generate git branch name based off taskwarrior ticket
def gbranch [name: string]: [nothing -> string] {
  let branch_name = $name |
    str downcase |
    str replace ' ' '-' |
    str replace '[^a-z0-9-]' '' |
    str trim -c '-'

  let active = tactive
  if ('ticket' not-in $active) {
    error make -u {
      msg: "Active task has no ticket"
    }
    return
  }

  $'($active.ticket)/($branch_name)'
}

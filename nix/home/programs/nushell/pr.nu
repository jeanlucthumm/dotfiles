# New PR setup (offline version - no Notion/AI calls)
def prsetup-offline [
  ticket_id: string,       # Ticket ID (e.g., "CORA2-304")
  name: string,            # Branch name (e.g., "authfix")
  --desc: string,          # Optional ticket description for task
  --subdir: string,        # Optional moonrepo subdirectory (skips fzf prompt)
  branch_start?: string,   # Starting point for new branch
]: [nothing -> nothing] {

  if ($desc != null) {
    task add ('ticket:' + $ticket_id) $desc
  }

  # Get git root directory and create worktree relative to its parent
  let git_root = git rev-parse --show-toplevel | str trim
  let worktree_path = ($git_root | path dirname | path join $name)

  if ($branch_start == null) {
    git worktree add -b $'($ticket_id)/($name)' $worktree_path
  } else {
    git worktree add -b $'($ticket_id)/($name)' $worktree_path $branch_start
  }

  # Run gen-proto.sh in the new work tree
  cd $worktree_path
  ./gen-proto.sh
  cd -

  # Allow direnv on all top-level directories with .envrc files
  glob $"($worktree_path)/*/.envrc" | each { |f|
    let dir = ($f | path dirname)
    print $"Allowing direnv in ($dir)"
    direnv allow $dir
  }

  # Also allow direnv on the worktree root if it has .envrc
  if ($worktree_path | path join ".envrc" | path exists) {
    print $"Allowing direnv in ($worktree_path)"
    direnv allow $worktree_path
  }

  # Check if working in a monorepo subdirectory
  let selected_subdir = if ($subdir != null) {
    $subdir
  } else {
    let subdirs = glob ($worktree_path | path join "*") --no-file | path basename
    try {
      $subdirs | str join "\n" | fzf --height=40% --prompt="Select subdirectory (ESC for root): "
    } catch { "" }
  }

  let target_dir = if ($selected_subdir | is-empty) {
    $worktree_path
  } else {
    let full_subdir_path = ($worktree_path | path join $selected_subdir)
    print $"Running direnv allow in: ($full_subdir_path)"
    direnv allow $full_subdir_path
    $full_subdir_path
  }

  # If we selected a monorepo subdirectory, create PR.md and run setup
  if $target_dir != $worktree_path {
    cd $target_dir
    if ($desc != null) {
      prmd $desc
    } else {
      prmd
    }
    try {
      ^just setup err> /dev/null out> /dev/null
    } catch {
      # Silently ignore any failures (missing justfile/setup recipe, etc.)
    }
    cd -
  }

  # Open new kitty tab (macOS) or window (Linux)
  if ($nu.os-info.name == "macos") {
    kitten @ launch --type=tab --tab-title $name --cwd $target_dir
  } else {
    kitty --detach --directory $target_dir
  }
}

# New PR setup
def prsetup [
  ticket_id: string,       # Ticket ID (e.g., "CORA2-304")
  --subdir: string,        # Optional moonrepo subdirectory (skips fzf prompt)
  branch_start?: string,   # Starting point for new branch
]: [nothing -> nothing] {

  # Fetch ticket info from Notion
  let t = ticket $ticket_id
  let desc = $t.title

  let prompt = "Create a git branch name for the given ticket title. Keep it at most two combined words, no spaces, no '-', keep it short. Output only the git branch name and nothing else. Some examples:

restart
chat
uipolish
signin
terraconv
routing
mcpcreds
ddos"

  let resp = $desc | aichat $prompt

  # Ask for confirmation on the name
  print $"Suggested branch name: ($resp)"
  let confirmation = input "Use this name? (y/N): "

  let name = if ($confirmation | str downcase) in ["y", "yes"] {
    $resp
  } else {
    input "Enter branch name: "
  }

  task add ('ticket:' + $ticket_id) $desc

  # Get git root directory and create worktree relative to its parent
  let git_root = git rev-parse --show-toplevel | str trim
  let worktree_path = ($git_root | path dirname | path join $name)

  if ($branch_start == null) {
    git worktree add -b $'($ticket_id)/($name)' $worktree_path
  } else {
    git worktree add -b $'($ticket_id)/($name)' $worktree_path $branch_start
  }

  # Run gen-proto.sh in the new work tree
  cd $worktree_path
  ./gen-proto.sh
  cd -

  # Allow direnv on all top-level directories with .envrc files
  glob $"($worktree_path)/*/.envrc" | each { |f|
    let dir = ($f | path dirname)
    print $"Allowing direnv in ($dir)"
    direnv allow $dir
  }

  # Also allow direnv on the worktree root if it has .envrc
  if ($worktree_path | path join ".envrc" | path exists) {
    print $"Allowing direnv in ($worktree_path)"
    direnv allow $worktree_path
  }

  # Check if working in a monorepo subdirectory
  let selected_subdir = if ($subdir != null) {
    $subdir
  } else {
    let subdirs = glob ($worktree_path | path join "*") --no-file | path basename
    try {
      $subdirs | str join "\n" | fzf --height=40% --prompt="Select subdirectory (ESC for root): "
    } catch { "" }
  }

  let target_dir = if ($selected_subdir | is-empty) {
    $worktree_path
  } else {
    let full_subdir_path = ($worktree_path | path join $selected_subdir)
    print $"Running direnv allow in: ($full_subdir_path)"
    direnv allow $full_subdir_path
    $full_subdir_path
  }

  # If we selected a monorepo subdirectory, create PR.md and run setup
  if $target_dir != $worktree_path {
    cd $target_dir
    prmd $t.contents
    try {
      ^just setup err> /dev/null out> /dev/null
    } catch {
      # Silently ignore any failures (missing justfile/setup recipe, etc.)
    }
    cd -
  }

  # Open new kitty tab (macOS) or window (Linux)
  if ($nu.os-info.name == "macos") {
    kitten @ launch --type=tab --tab-title $name --cwd $target_dir
  } else {
    kitty --detach --directory $target_dir
  }
}

# Sync existing PR branch from another machine
def prsync [
  branch?: string,  # Branch name; if omitted, select via fzf from ngit branch
]: [nothing -> nothing] {
  # Fetch latest remote branches first
  git fetch --prune

  # Determine branch: use provided or pick via fzf from ngit branch (including remote)
  let sel_branch = if ($branch == null) {
    let choices = ngit branch --all | get branch | to text
    let choice = ($choices | fzf --height=40% --prompt="Select branch: ")
    if ($choice | is-empty) {
      print "No branch selected; aborting prsync."
      return
    }
    $choice
  } else { $branch }

  # Extract the short name from the branch (part after the slash)
  let name = $sel_branch | split row '/' | last

  # Get git root directory and create worktree relative to its parent
  let git_root = git rev-parse --show-toplevel | str trim
  let worktree_path = ($git_root | path dirname | path join $name)

  # Check if worktree already exists
  let worktree_exists = ($worktree_path | path exists)

  if not $worktree_exists {
    print $"Creating new worktree at ($worktree_path)"

    # Create worktree tracking the remote branch
    git worktree add $worktree_path $sel_branch

    # Run gen-proto.sh in the new work tree
    if ($worktree_path | path join "gen-proto.sh" | path exists) {
      print "Running gen-proto.sh"
      cd $worktree_path
      ./gen-proto.sh
      cd -
    }
  } else {
    print $"Worktree already exists at ($worktree_path), skipping setup"
  }

  # Check if working in a monorepo subdirectory
  let target_dir = if not $worktree_exists {
    let subdirs = glob ($worktree_path | path join "*") --no-file | path basename
    let subdir = try {
      $subdirs | str join "\n" | fzf --height=40% --prompt="Select subdirectory (ESC for root): "
    } catch { "" }

    if ($subdir | is-empty) {
      $worktree_path
    } else {
      let full_subdir_path = ($worktree_path | path join $subdir)
      print $"Running direnv allow in: ($full_subdir_path)"
      direnv allow $full_subdir_path
      $full_subdir_path
    }
  } else {
    $worktree_path
  }

  # Open new kitty tab (macOS) or window (Linux)
  if ($nu.os-info.name == "macos") {
    print $"Opening kitty tab: ($name)"
    kitten @ launch --type=tab --tab-title $name --cwd $target_dir
  } else {
    print $"Opening kitty window in: ($target_dir)"
    kitty --detach --directory $target_dir
  }
}

# Open new kitty tab in an existing worktree
def prtab [
  name: string  # Worktree name (e.g., master, dailyreport, thinking)
]: [nothing -> nothing] {
  # Parse git worktree list output to find the worktree path
  let worktrees = git worktree list
    | lines
    | parse "{path} {commit} [{branch}]"

  let matches = $worktrees | where path =~ $name

  if ($matches | is-empty) {
    error make -u {
      msg: $"Worktree '($name)' not found"
    }
  }

  let worktree = $matches | first

  # Open new kitty tab (macOS) or window (Linux)
  if ($nu.os-info.name == "macos") {
    kitten @ launch --type=tab --tab-title $name --cwd $worktree.path
  } else {
    kitty --detach --directory $worktree.path
  }
}

# Merge PR and clean up worktree
def --env prmerge []: [nothing -> nothing] {
  let initial_dir = (pwd)

  # Get current branch name and worktree directory
  let branch_name = git head
  let worktree = git rev-parse --show-toplevel | path basename

  # Get base branch from the PR
  let base_branch = gh pr view --json baseRefName -q '.baseRefName' | str trim

  # Change to the worktree root
  cd (git rev-parse --show-toplevel)

  print $"Merging PR for branch: ($branch_name)"
  print $"Base branch: ($base_branch)"
  print $"Current worktree: ($worktree)"

  # Ask for confirmation
  let confirmation = input "Proceed with merge and cleanup? (y/N): "
  if not (($confirmation | str downcase) in ["y", "yes"]) {
    print "Aborted"
    cd $initial_dir
    return
  }

  # Merge the PR (without deleting branch locally)
  gh pr merge -m

  # Navigate to base branch worktree
  cd $"../($base_branch)"

  # Remove the worktree we were just in
  sudo git worktree remove $"../($worktree)"

  # Delete local and remote branch
  git branch -D $branch_name
  git push origin --delete $branch_name

  # Pull master to catch up to the merge
  git pull

  # Clean up any other stale remote tracking branches
  git remote prune origin

  print $"Successfully merged and cleaned up ($branch_name)"

  # Navigate to home directory
  cd ~

  # On macOS, close the kitty tab after all cleanup is complete
  if ($nu.os-info.name == "macos") {
    kitten @ close-tab --self
  }
}

# Discard PR and clean up worktree (counterpart to prmerge)
def --env prdelete []: [nothing -> nothing] {
  let initial_dir = (pwd)

  # Get current branch name and worktree directory
  let branch_name = git head
  let worktree = git rev-parse --show-toplevel | path basename

  # Get base branch from PR if it exists, otherwise detect default branch
  let base_branch = try {
    gh pr view --json baseRefName -q '.baseRefName' | str trim
  } catch {
    # No PR exists, detect default branch from available worktrees
    if ("../main" | path exists) { "main" } else { "master" }
  }

  # Change to the worktree root
  cd (git rev-parse --show-toplevel)

  # Check for uncommitted changes
  let status = git status --porcelain | str trim
  if ($status | is-not-empty) {
    print "Error: Worktree has uncommitted changes. Commit or stash them first."
    print $status
    cd $initial_dir
    return
  }

  print $"Discarding PR for branch: ($branch_name)"
  print $"Base branch: ($base_branch)"
  print $"Current worktree: ($worktree)"

  # Ask for confirmation
  let confirmation = input "Proceed with discard and cleanup? (y/N): "
  if not (($confirmation | str downcase) in ["y", "yes"]) {
    print "Aborted"
    cd $initial_dir
    return
  }

  # Close the PR if it exists (ignore errors if no PR)
  try {
    gh pr close --delete-branch
  } catch { }

  # Navigate to base branch worktree
  cd $"../($base_branch)"

  # Remove the worktree we were just in
  sudo git worktree remove $"../($worktree)"

  # Delete local branch (remote already deleted by gh pr close --delete-branch)
  try {
    git branch -D $branch_name
  } catch { }

  # Clean up any other stale remote tracking branches
  git remote prune origin

  print $"Successfully discarded and cleaned up ($branch_name)"

  # Navigate to home directory
  cd ~

  # On macOS, close the kitty tab after all cleanup is complete
  if ($nu.os-info.name == "macos") {
    kitten @ close-tab --self
  }
}

# Delete a branch and any associated worktrees
def prcleanup [
  branch?: string,  # Branch name; if omitted, select via fzf from ngit branch
]: [nothing -> nothing] {
  let initial_dir = (pwd)

  # Determine branch: use provided or pick via fzf from ngit branch
  let sel_branch = if ($branch == null) {
    let choices = ngit branch | get branch | to text
    let choice = ($choices | fzf --height=40% --prompt="Select branch to delete: ")
    if ($choice | is-empty) {
      print "No branch selected; aborting prcleanup."
      return
    }
    $choice
  } else { $branch }

  if ($sel_branch in ["master", "main"]) {
    print $"Refusing to delete protected branch: ($sel_branch)"
    return
  }

  # Ensure we are inside a git repository
  let git_check = (try { git rev-parse --show-toplevel | str trim } catch { "" })
  if ($git_check | is-empty) {
    print "Not inside a git repository; aborting prcleanup."
    return
  }

  let confirmation = input $"Delete branch '($sel_branch)' and any associated worktrees? (y/N): "
  if not (($confirmation | str downcase) in ["y", "yes"]) {
    print "Aborted prcleanup."
    return
  }

  # Find and remove any worktrees associated with this branch
  let worktrees = ngit worktree list
  let target_worktrees = ($worktrees | where branch == $sel_branch)

  if ($target_worktrees | is-empty) {
    print $"No worktrees found for branch '($sel_branch)'."
  } else {
    let target_paths = ($target_worktrees | get path)
    let control_candidates = ($worktrees | where $it.path not-in $target_paths)

    if ($control_candidates | is-empty) {
      print $"Found worktrees for '($sel_branch)' but no alternate worktree to run 'git worktree remove' from; skipping worktree removal."
    } else {
      let cleanup_dir = $control_candidates.0.path
      cd $cleanup_dir

      for wt in $target_worktrees {
        print $"Removing worktree at ($wt.path)"
        git worktree remove $wt.path
      }
    }
  }

  # Delete local branch
  if (git branch --list $sel_branch | str trim | is-not-empty) {
    print $"Deleting local branch '($sel_branch)'"
    git branch -D $sel_branch
  } else {
    print $"Local branch '($sel_branch)' not found."
  }

  # Optionally delete remote branch
  let delete_remote = input "Also delete remote branch? (y/N): "
  if (($delete_remote | str downcase) in ["y", "yes"]) {
    git push origin --delete $sel_branch
  }

  cd $initial_dir
}

# Create PR.md from template with optional description
def prmd [
  desc?: string  # Optional PR description to populate in the template
]: [nothing -> nothing] {
  let template = open ~/nix/templates/PR.md

  if ($desc != null) {
    # Find the PR Description section and add the description after it
    # Using regex to match the section header and preserve formatting
    let updated = $template | str replace --regex '(## PR Description\n)(\n)?' $"$1\n($desc)\n\n"
    $updated | save PR.md
  } else {
    $template | save PR.md
  }
}

# Fetch unresolved review comments for the current PR
def prcomments [
  --llm (-l)  # Copy formatted output to clipboard for LLM
]: [nothing -> table<path: string, line: int, body: string>] {
  let repo_info = gh repo view --json owner,name | from json
  let owner = $repo_info.owner.login
  let repo = $repo_info.name
  let pr_number = gh pr view --json number -q '.number' | str trim

  let comments = gh api graphql -f $"owner=($owner)" -f $"repo=($repo)" -F $"number=($pr_number)" -f query='
    query($owner: String!, $repo: String!, $number: Int!) {
      repository(owner: $owner, name: $repo) {
        pullRequest(number: $number) {
          reviewThreads(first: 100) {
            nodes {
              isResolved
              comments(first: 10) {
                nodes {
                  path
                  line
                  body
                }
              }
            }
          }
        }
      }
    }
  ' | from json | get data.repository.pullRequest.reviewThreads.nodes
    | where isResolved == false
    | each { |thread|
      let comments = $thread.comments.nodes
      let first = $comments.0
      {
        path: $first.path
        line: $first.line
        body: ($comments | get body | str join "\n---\n")
      }
    }

  if $llm {
    $"<review>

```csv
($comments | to csv)
```

</review>

Address the simple comments you agree with, one commit per, then let's talk about the ones that require design or you disagree with \(if any\)." | clip
  } else {
    $comments
  }
}

# Resolve all review threads on the current PR
def prresolve []: [nothing -> nothing] {
  let repo_info = gh repo view --json owner,name | from json
  let owner = $repo_info.owner.login
  let repo = $repo_info.name
  let pr_number = gh pr view --json number -q '.number' | str trim

  # Get all unresolved review thread IDs
  let thread_ids = gh api graphql -f $"owner=($owner)" -f $"repo=($repo)" -F $"number=($pr_number)" -f query='
    query($owner: String!, $repo: String!, $number: Int!) {
      repository(owner: $owner, name: $repo) {
        pullRequest(number: $number) {
          reviewThreads(first: 100) {
            nodes {
              id
              isResolved
            }
          }
        }
      }
    }
  ' | from json | get data.repository.pullRequest.reviewThreads.nodes
    | where isResolved == false
    | get id

  if ($thread_ids | is-empty) {
    print "No unresolved review threads"
    return
  }

  # Resolve each thread
  for thread_id in $thread_ids {
    gh api graphql -f $"threadId=($thread_id)" -f query='
      mutation($threadId: ID!) {
        resolveReviewThread(input: {threadId: $threadId}) {
          thread { isResolved }
        }
      }
    ' | ignore
  }

  print $"Resolved ($thread_ids | length) review threads"
}

# Open a new kitty tab in the same directory for PR composition
def prcompose []: [nothing -> nothing] {
  if ($nu.os-info.name != "macos") {
    print "prcompose is only supported on macOS"
    return
  }

  # Get current tab name from kitty
  let kitty_state = kitten @ ls | from json
  let current_tab = $kitty_state
    | get 0.tabs
    | where is_focused == true
    | get 0.title

  let new_tab_name = $"($current_tab)-compose"
  let current_dir = pwd

  kitten @ launch --type=tab --tab-title $new_tab_name --cwd $current_dir
}

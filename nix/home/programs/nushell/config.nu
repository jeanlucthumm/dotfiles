# Helper for ipv4 address
def ipv4 [iface: string]: [nothing -> string] {
  sys net | where name == $iface | get 0.ip | where protocol == "ipv4" | get 0.address
}

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

# New PR setup
def prsetup [
  ticket: string,       # Ticket ID
  desc: string          # Description of the ticket
  branch_start?: string, # Starting point for new branch
]: [nothing -> nothing] {

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

  task add ('ticket:' + $ticket) $desc

  # Get git root directory and create worktree relative to its parent
  let git_root = git rev-parse --show-toplevel | str trim
  let worktree_path = ($git_root | path dirname | path join $name)

  if ($branch_start == null) {
    git worktree add -b $'($ticket)/($name)' $worktree_path
  } else {
    git worktree add -b $'($ticket)/($name)' $worktree_path $branch_start
  }

  # Run gen-proto.sh in the new work tree
  cd $worktree_path
  ./gen-proto.sh
  cd -

  # Check if working in a monorepo subdirectory
  let monorepo_answer = (input "Will you be working in a subdirectory of a monorepo? (y/N): " | str downcase)
  let in_monorepo_subdir = $monorepo_answer in ["y", "yes"]

  let target_dir = if $in_monorepo_subdir {
    let subdir = input "Enter the relative path to the subdirectory: "
    let full_subdir_path = ($worktree_path | path join $subdir)

    if ($full_subdir_path | path exists) {
      print $"Running direnv allow in: ($full_subdir_path)"
      direnv allow $full_subdir_path
      $full_subdir_path
    } else {
      print $"Warning: Subdirectory ($full_subdir_path) does not exist. Using top level."
      $worktree_path
    }
  } else {
    $worktree_path
  }

  # If we selected a monorepo subdirectory, attempt a best-effort `make setup`
  if $in_monorepo_subdir {
    try {
      cd $target_dir
      ^make setup err> /dev/null out> /dev/null
      cd -
    } catch {
      # Silently ignore any failures (missing Makefile/setup rule, etc.)
    }
  }

  # Open new kitty tab with the work tree name (macOS only)
  if ($nu.os-info.name == "macos") {
    kitten @ launch --type=tab --tab-title $name --cwd $target_dir
  }
}

# Sync existing PR branch from another machine
def prsync [
  branch?: string,  # Branch name; if omitted, select via fzf from ngit branch
]: [nothing -> nothing] {
  # Determine branch: use provided or pick via fzf from ngit branch
  let sel_branch = if ($branch == null) {
    let choices = ngit branch | get branch | to text
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
  let target_dir = if not $worktree_exists and ((input "Will you be working in a subdirectory of a monorepo? (y/N): " | str downcase) in ["y", "yes"]) {
    let subdir = input "Enter the relative path to the subdirectory: "
    let full_subdir_path = ($worktree_path | path join $subdir)

    if ($full_subdir_path | path exists) {
      print $"Running direnv allow in: ($full_subdir_path)"
      direnv allow $full_subdir_path
      $full_subdir_path
    } else {
      print $"Warning: Subdirectory ($full_subdir_path) does not exist. Using top level."
      $worktree_path
    }
  } else {
    $worktree_path
  }

  # Open new kitty tab with the work tree name (macOS only)
  if ($nu.os-info.name == "macos") {
    print $"Opening kitty tab: ($name)"
    kitten @ launch --type=tab --tab-title $name --cwd $target_dir
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

  # Open new kitty tab with the worktree name (macOS only)
  if ($nu.os-info.name == "macos") {
    kitten @ launch --type=tab --tab-title $name --cwd $worktree.path
  } else {
    print $"Not on macOS, would open tab at: ($worktree.path)"
  }
}

# Pipe in .env file and load into environment variables.
def "from dotenv" []: [string -> record] {
    lines |
    where ($it | str trim) != "" |
    where not ($it | str trim | str starts-with "#") |
    split column -n 2 '=' |
    rename key value |
    update value { str trim --char '"' } |
    transpose --header-row |
    into record
}

# rg wrapper
def nrg [pattern: string]: [nothing -> table<file: string, line: int, text: string>] {
  $'[(rg --json $pattern)]' |
    from json |
    where type == "match" |
    select data.path.text data.line_number data.lines.text |
    rename file line text
}

# Asks an AI to find a suitable nushell command
def aihelp [query: string]: [nothing -> string] {
  let msg = $"Recommend a nushell command for the following query: ($query)"
  help commands | select name description | to csv | aichat $msg
}

alias lss = ls

def ls --wrapped [...rest]: [nothing -> string] {
  ^eza -s name --group-directories-first -1 --icons=always ...$rest
}

def ssh --wrapped [...rest] {
  with-env { TERM: xterm-256color } { ^ssh ...$rest }
}

# Taskwarrior: Stop active task
def tstop []: [nothing -> string] {
  task +ACTIVE stop
}

# Taskwarrior: Start first ready task if no task is active
def tstart []: [nothing -> string] {
  let active_list = task +ACTIVE export | from json
  if not ($active_list | is-empty) {
    return
  }

  let context_name = (try {
      task _get rc.context | str trim
    } catch {
      ""
    })
  let context_name = $context_name | str trim
  let context_arg = if ($context_name | is-empty) or (($context_name | str downcase) == "none") {
    []
  } else {
    [$"rc.context=($context_name)"]
  }

  let ready_tasks = if ($context_arg | is-empty) {
    task export ready | from json
  } else {
    task ...$context_arg export ready | from json
  }
  if ($ready_tasks | is-empty) {
    print "No ready tasks available"
    return
  }

  task ...$context_arg start $ready_tasks.0.id
}

# Taskwarrior: Add a child task to the active task, inheriting all properties
def tchild [
  parent: int,    # Which parent to add the child to
  desc: string,   # Description of the child task
]: [nothing -> string] {
  let parent_task_list = task $parent export | from json
  if ($parent_task_list | is-empty) {
    error make {
      msg: "Parent not found"
      label: {
        text: "parent id"
        span: (metadata $parent).span
      }
    }
    return
  }
  let parent_task = $parent_task_list.0

  # Copy over common props
  let skip_list = [
    "id" "description" "entry" "modified" "status" "uuid" "urgency" "depends" "start"
  ]
  let common_props = $parent_task | columns | where not ($it in $skip_list)
  let args = $common_props | each { |prop|
    $"($prop):($parent_task | get $prop)"
  }
  let args = $args ++ [$"blocks:($parent)", $"description:($desc)"]

  # Create the child task
  task add ...$args
}

# Taskwarrior: Break down an active task into one or more smaller ones and start one
def tbreak [
  ...descs: string,   # One or more child task descriptions
]: [nothing -> string] {
  let active = __tactive_select

  if ($descs | is-empty) {
    error make -u { msg: "No child description(s) provided" }
  }

  # Create all requested child tasks
  $descs | each { |d| tchild $active.id $d }

  # Stop current task and start the most recently created child
  let new_task = task export newest | from json | get 0
  task stop $active.id
  task start $new_task.id
}

# Taskwarrior: Complete current task and start the parent
def tparent []: [nothing -> string] {
  let task_record = __tactive_select
  let parent = $task_record.uuid | __tparent

  if ($parent.status != "pending") {
    print -e $"Parent not pending. UUID: ($parent.uuid)"
    return
  }

  # Check for pending siblings: siblings are other children the parent depends on
  let parent_deps = (if ((($parent | columns) | any { |c| $c == "depends" })) { $parent.depends } else { [] })
  let siblings = task export |
    from json |
    where uuid in $parent_deps |
    where uuid != $task_record.uuid |
    where status == "pending"

  if ($siblings | is-not-empty) {
    let next_sibling = ($siblings | first)
    task done $task_record.id
    task start $next_sibling.id
    print $"Started sibling instead of parent: (#($next_sibling.id)) ($next_sibling.description)"
    return
  }

  task done $task_record.id
  task start $parent.id
}

# Taskwarrior: Add task as children to the active's parent
def tsibling [
  desc: string,   # Description of the sibling task
  id?: int, # Optional id of the task to add a sibling to. Default to active task.
]: [nothing -> string] {
  let parent = if ($id == null) {
    tactive | get uuid | __tparent
  } else {
    $id | __tlookup | get uuid | __tparent
  }

  if ($parent.status != "pending") {
    print -e $"Parent not pending. UUID: ($parent.uuid)"
    return
  }
  
  tchild $parent.id $desc
}

def tactive []: [nothing -> record] {
  let active_list = task +ACTIVE export | from json
  if ($active_list | is-empty) {
    error make -u {
      msg: "No active task"
    }
  }
  $active_list.0
}

# Stop active task and immediately start planning project in timew.
def tplan []: [nothing -> string] {
  let active = tactive
  task done $active.id
  timew start plan
  task ready
}

def __tparent []: [string -> record] {
  let uuid = $in
  let parents = task export |
    from json |
    default [] depends |
    where $uuid in $it.depends
  if ($parents | is-empty) {
    error make -u {
      msg: "No parents"
    }
  }
  $parents.0
}

def __tlookup []: [int -> record] {
  let result = task $in export | from json

  if ($result | is-empty) {
    error make -u {
      msg: "No such id"
    }
  }

  $result.0
}

# Get active task, prompting with fzf if multiple are active
def __tactive_select []: [nothing -> record] {
  let active_list = task +ACTIVE export | from json

  if ($active_list | is-empty) {
    error make -u {
      msg: "No active task"
    }
  }

  if ($active_list | length) == 1 {
    return ($active_list | first)
  }

  # Multiple active tasks - use fzf to select
  let selection = ($active_list
    | each { |task| $"($task.id): ($task.description)" }
    | to text
    | fzf --height=40% --prompt="Select active task: ")

  if ($selection | is-empty) {
    error make -u {
      msg: "No task selected"
    }
  }

  let selected_id = ($selection | split row ":" | first | into int)
  $active_list | where id == $selected_id | first
}

# Concatenate file contents with labels.
def label-files []: [list<path> -> string] {
  each { |file|
    let ext = ($file | path parse | get extension)
    $"Contents of ($file):\n```($ext)\n(open $file --raw | str trim)\n```\n\n"
  } |
  str join
}

# Git status
def "ngit status" []: [nothing -> table<status: string, file: string>] {
  git status --porcelain | from ssv -m 1 -n | rename status file
}

# Nushell wrapper for gh
def ngh [] {}

# Nushell wrapper for gh pr
def "ngh pr" [] {}

# GitHub PR checks
def "ngh pr checks" []: [nothing -> table<name: string, link: string, state: string>] {
  gh pr checks --json name,link,state | from json
}

# Merge PR and clean up worktree
def --env prmerge []: [nothing -> nothing] {
  # Get current branch name and worktree directory
  let branch_name = git head
  let worktree = git rev-parse --show-toplevel | path basename

  # Change to the worktree root
  cd (git rev-parse --show-toplevel)

  print $"Merging PR for branch: ($branch_name)"
  print $"Current worktree: ($worktree)"

  # Ask for confirmation
  let confirmation = input "Proceed with merge and cleanup? (y/N): "
  if not (($confirmation | str downcase) in ["y", "yes"]) {
    print "Aborted"
    return
  }

  # Merge the PR (without deleting branch locally)
  gh pr merge -m

  # Navigate to master worktree
  cd ../master

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

# Copy piped in contents to clipboard.
def clip []: [string -> nothing] {
  if ($env | get --optional TMUX | is-not-empty) {
    $in | tmux loadb -
  } else if ($nu.os-info.name == "linux") {
    if ($env.XDG_SESSION_TYPE == "wayland") {
      $in | wl-copy
    } else {
      $in | xclip -selection clipboard
    }
  } else if ($nu.os-info.name == "macos") {
    $in | pbcopy
  } else {
    echo "Unsupported OS"
  }
}

# Paste clipboard contents to stdout.
def paste []: [nothing -> string] {
  if ($env | get --optional TMUX | is-not-empty) {
    tmux showb -t 0
  } else if ($nu.os-info.name == "linux") {
    if ($env.XDG_SESSION_TYPE == "wayland") {
      wl-paste
    } else {
      xclip -selection clipboard -o
    }
  } else if ($nu.os-info.name == "macos") {
    pbpaste
  } else {
    echo "Unsupported OS"
  }
}

# Takes git diff output and wraps it in a code block with diff syntax highlighting.
def label-diff []: [string -> string] {
  $"```diff\n($in)\n```"
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

# Launch Claude Code in ~/nix with a query for AI-enabled config updates
def nmod [query: string]: [nothing -> nothing] {
  cd ~/nix
  # Original with allowedTools flag (commented out - Claude Code won't take the query if this flag is present for some reason)
  # claude --permission-mode acceptEdits --allowedTools "List Read Bash(find:*)" $query
  claude --permission-mode acceptEdits $query
}

# See https://github.com/nushell/nushell/issues/5552#issuecomment-2113935091
let abbreviations = {
  g: 'git'
  gt: 'git tree'
  gs: 'git status'
  gd: 'git d'
  ge: 'git de'
  gm: 'git commit -m'
  ga: 'git add -A'
  gda: 'git add -A; git d'
  gwl: 'git worktree list'
  yda: 'yadm add -u -p; yadm d'
  ym: 'yadm commit -m'
  tr: 'task ready'
  ta: 'task active'
}

$env.config = {
  edit_mode: "emacs"
  keybindings: [
    {
      name: backward_word
      modifier: control
      keycode: char_h
      mode: [emacs, vi_normal, vi_insert]
      event: { edit: movewordleft }
    }
    {
      name: forward_word
      modifier: control
      keycode: char_l
      mode: [emacs, vi_normal, vi_insert]
      event: { edit: movewordright }
    }
    # Keybinds for fish-like abbreviations
    {
      name: abbr_menu
      modifier: none
      keycode: enter
      mode: [emacs, vi_normal, vi_insert]
      event: [
          { send: menu name: abbr_menu }
          { send: enter }
      ]
    }
    {
      name: abbr_menu
      modifier: none
      keycode: space
      mode: [emacs, vi_normal, vi_insert]
      event: [
          { send: menu name: abbr_menu }
          { edit: insertchar value: ' '}
      ]
    }
    # End fish
  ]
  menus: [
    # Menu for fish like abbreviations
    {
      name: abbr_menu
      only_buffer_difference: false
      marker: none
      type: {
        layout: columnar
        columns: 1
        col_width: 20
        col_padding: 2
      }
      style: {
        text: green
        selected_text: green_reverse
        description_text: yellow
      }
      source: { |buffer, position|
        let match = $abbreviations | columns | where $it == $buffer
        if ($match | is-empty) {
          { value: $buffer }
        } else {
          { value: ($abbreviations | get $match.0) }
        }
      }
    }
  ]
}

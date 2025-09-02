
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

  if ($branch_start == null) {
    git worktree add -b $'($ticket)/($name)' ('../' + $name)
  } else {
    git worktree add -b $'($ticket)/($name)' ('../' + $name) $branch_start
  }

  # Run gen-proto.sh in the new work tree
  cd ('../' + $name)
  ./gen-proto.sh
  cd -

  # Open new kitty tab with the work tree name (macOS only)
  if ($nu.os-info.name == "macos") {
    kitten @ launch --type=tab --tab-title $name --cwd ('../' + $name)
  }
}

# Pipe in .env file and load into environment variables.
def from-dotenv []: [string -> record] {
    lines |
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

  let ready_tasks = task export ready | from json
  if ($ready_tasks | is-empty) {
    print "No ready tasks available"
    return
  }

  task start $ready_tasks.0.id
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

# Taskwarrior: Break down an active task into a smaller one and start it
def tbreak [
  desc: string,   # Description of the child task
]: [nothing -> string] {
  let active = tactive

  tchild $active.id $desc

  # Stop current task and start the new one
  let new_task = task export newest | from json | get 0
  task stop $active.id
  task start $new_task.id
}

# Taskwarrior: Complete current task and start the parent
def tparent []: [nothing -> string] {
  let active = tactive
  let parent = $active.uuid | __tparent

  if ($parent.status != "pending") {
    print -e $"Parent not pending. UUID: ($parent.uuid)"
    return
  }

  task done $active.id
  task start $parent.id
}

# Taskwarrior: Add task as children to the active's parent
def tsibling [
  desc: string,   # Description of the sibling task
  id?: int, # Optional id of the task to add a sibling to. Default to active task.
]: [nothing -> string] {
  let parent = if (id == null) {
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

# Concatenate file contents with labels.
def label-files []: [list<path> -> string] {
  each { |file|
    let ext = ($file | path parse | get extension)
    $"Contents of ($file):\n```($ext)\n(open $file --raw | str trim)\n```\n\n"
  } |
  str join
}

# Git status
def ngit-status []: [nothing -> table<status: string, file: string>] {
  git status --porcelain | from ssv -m 1 -n | rename status file
}

# Merge PR and clean up worktree
def prmerge []: [nothing -> nothing] {
  # Get current branch name and worktree directory
  let branch_name = git head
  let current_dir = pwd | path basename
  
  print $"Merging PR for branch: ($branch_name)"
  print $"Current worktree: ($current_dir)"
  
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
  git worktree remove $"../($current_dir)"
  
  # Delete local and remote branch
  git branch -D $branch_name
  git push origin --delete $branch_name
  
  # Pull master to catch up to the merge
  git pull
  
  # Clean up any other stale remote tracking branches
  git remote prune origin
  
  print $"Successfully merged and cleaned up ($branch_name)"
}

# Copy piped in contents to clipboard.
def clip []: [string -> nothing] {
  if ($env | get -o TMUX | is-not-empty) {
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
  if ($env | get -o TMUX | is-not-empty) {
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
def ngit-prcontext [
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
  gda: 'git add -A; git d'
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

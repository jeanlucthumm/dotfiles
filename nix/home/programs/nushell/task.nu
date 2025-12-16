# Parse taskwarrior JSON export with proper datetime conversion
def "from taskwarrior" []: [string -> table] {
  let datetime_fields = [start end wait entry modified due scheduled until]

  $in | from json | each { |task|
    $datetime_fields | reduce --fold $task { |field, acc|
      if ($field in ($acc | columns)) and ($acc | get $field) != null {
        $acc | update $field { $in | into datetime }
      } else {
        $acc
      }
    }
  }
}

# Taskwarrior: Show parent chain for a task (root to task)
def tchain [
  id?: int  # Task ID (defaults to first ready task)
]: [nothing -> table<id: int, description: string>] {
  let task = if ($id == null) {
    let ready = __tready
    if ($ready | is-empty) {
      error make -u { msg: "No ready tasks" }
    }
    $ready | first
  } else {
    $id | __tlookup
  }

  # Build chain from task up to root
  mut chain = [$task]
  mut current = $task

  loop {
    let parents = $current.uuid | __tparents
    if ($parents | is-empty) {
      break
    }
    $current = $parents | first
    $chain = $chain | prepend $current
  }

  $chain | select id description
}

# Get ready tasks filtered by current context, excluding active
def __tready []: [nothing -> list<record>] {
  let context = task _get rc.context | str trim
  let ready = task export ready | from json | where ($it.start? == null)

  if ($context | is-empty) or ($context | str downcase) == "none" {
    $ready
  } else {
    $ready | where ($it.project? | default "" | str starts-with $context)
  }
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

  let ready = __tready
  if ($ready | is-empty) {
    print "No ready tasks available"
    return
  }

  task start ($ready | first | get id)
}

# Taskwarrior: Add child task(s) to a parent task, inheriting all properties
def tchild [
  parent: int,        # Which parent to add the child to
  ...descs: string,   # One or more child task descriptions
]: [nothing -> list<string>] {
  if ($descs | is-empty) {
    error make -u { msg: "No child description(s) provided" }
  }

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
  let base_args = $common_props | each { |prop|
    $"($prop):($parent_task | get $prop)"
  }

  # Create each child task
  $descs | each { |desc|
    let args = $base_args ++ [$"blocks:($parent)", $"description:($desc)"]
    task add ...$args
  }
}

# Taskwarrior: Add child task(s) to first ready task
def trchild [
  ...descs: string,   # One or more child task descriptions
]: [nothing -> list<string>] {
  let ready = __tready
  if ($ready | is-empty) {
    error make -u { msg: "No ready tasks" }
  }
  tchild ($ready | first | get id) ...$descs
  task ready
}

# Taskwarrior: Delay a task by setting wait
def twait [
  duration: string,   # Wait duration (e.g. 2d, 1w)
  --id (-i): int,     # Task ID (defaults to first ready)
]: [nothing -> string] {
  let task_id = if ($id == null) {
    let ready = __tready
    if ($ready | is-empty) {
      error make -u { msg: "No ready tasks" }
    }
    $ready | first | get id
  } else {
    $id
  }
  task $task_id mod $"wait:($duration)"
  if ($id == null) {
    task ready
  }
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
  tchild $active.id ...$descs

  # Stop current task and start the most recently created child
  let new_task = task export newest | from json | get 0
  task stop $active.id
  task start $new_task.id
}

# Taskwarrior: Complete current task and start the parent
def tparent []: [nothing -> nothing] {
  let task_record = __tactive_select
  let all_parents = $task_record.uuid | __tparents

  if ($all_parents | is-empty) {
    error make -u { msg: "No parents" }
  }

  # Filter to lowest parents (exclude ancestors of other parents)
  let lowest = $all_parents | __lowest_parents
  let parent = $lowest | __select_parent

  # Check for pending siblings: other deps of parent that aren't current task
  # Exclude waiting tasks (pending with wait set)
  let siblings = task export |
    from json |
    where uuid in ($parent.depends? | default []) |
    where uuid != $task_record.uuid |
    where status == "pending" and ($it not-has "wait")

  if ($siblings | is-not-empty) {
    let next_sibling = ($siblings | first)
    task done $task_record.id
    task start $next_sibling.id
    print $"\n(ansi cyan)($next_sibling.description)(ansi reset)"
    return
  }

  task done $task_record.id
  task start $parent.id
  print $"\n(ansi cyan)($parent.description)(ansi reset)"
}

# Taskwarrior: Add task as children to the active's parent
def tsibling [
  ...descs: string,   # One or more sibling task descriptions
  --id (-i): int,     # Optional id of the task to add a sibling to. Default to active task.
]: [nothing -> list<string>] {
  if ($descs | is-empty) {
    error make -u { msg: "No sibling description(s) provided" }
  }

  let task_uuid = if ($id == null) {
    tactive | get uuid
  } else {
    $id | __tlookup | get uuid
  }

  let all_parents = $task_uuid | __tparents
  if ($all_parents | is-empty) {
    error make -u { msg: "No parents" }
  }

  let parent = $all_parents | __lowest_parents | __select_parent
  tchild $parent.id ...$descs
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

# Return all pending direct parents (tasks that depend on this uuid)
def __tparents []: [string -> list<record>] {
  let uuid = $in
  task export | from json | where status == "pending" and ($it not-has "wait") | where ($uuid in ($it.depends? | default []))
}

# Check if task A transitively depends on task B (A is ancestor of B)
def __depends_on [ancestor_uuid: string, descendant_uuid: string]: [nothing -> bool] {
  let task = task $ancestor_uuid export | from json | first
  let deps = $task.depends? | default []

  if ($descendant_uuid in $deps) {
    return true
  }

  # Recurse through deps
  $deps | any { |d| __depends_on $d $descendant_uuid }
}

# Filter to "lowest" parents (remove any parent that depends on another parent)
def __lowest_parents []: [list<record> -> list<record>] {
  let parents = $in
  $parents | where { |p|
    not ($parents | any { |other|
      $other.uuid != $p.uuid and (__depends_on $p.uuid $other.uuid)
    })
  }
}

# Select a single pending parent, using fzf if multiple
def __select_parent []: [list<record> -> record] {
  let parents = $in | where status == "pending" and ($it not-has "wait")

  if ($parents | is-empty) {
    error make -u { msg: "No pending parents" }
  }

  if ($parents | length) == 1 {
    return ($parents | first)
  }

  # Multiple parents - use fzf to select
  let selection = ($parents
    | each { |t| $"($t.id): ($t.description)" }
    | to text
    | fzf --height=40% --prompt="Select parent: ")

  if ($selection | is-empty) {
    error make -u { msg: "No parent selected" }
  }

  let selected_id = ($selection | split row ":" | first | into int)
  $parents | where id == $selected_id | first
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

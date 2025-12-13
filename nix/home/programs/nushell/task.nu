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
  ...descs: string,   # One or more sibling task descriptions
  --id (-i): int,     # Optional id of the task to add a sibling to. Default to active task.
]: [nothing -> list<string>] {
  if ($descs | is-empty) {
    error make -u { msg: "No sibling description(s) provided" }
  }

  let parent = if ($id == null) {
    tactive | get uuid | __tparent
  } else {
    $id | __tlookup | get uuid | __tparent
  }

  if ($parent.status != "pending") {
    print -e $"Parent not pending. UUID: ($parent.uuid)"
    return
  }

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

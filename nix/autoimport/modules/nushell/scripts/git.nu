# Nushell wrapper for git
def ngit [] {}

# Nushell version of git branch
def "ngit branch" [
  --all (-a)  # Include remote branches not present locally
]: [nothing -> table<symbol: string, branch: string>] {
  let local = git branch | lines | parse "{symbol} {branch}" | str trim

  if $all {
    let local_names = $local | get branch

    # Get remote branches, strip origin/ prefix, exclude HEAD and local branches
    let remote_only = git branch -r |
      lines |
      str trim |
      where { |b| not ($b | str starts-with "origin/HEAD") } |
      each { |b| $b | str replace "origin/" "" } |
      where { |b| $b not-in $local_names } |
      each { |b| { symbol: "r", branch: $b } }

    $local | append $remote_only
  } else {
    $local
  }
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

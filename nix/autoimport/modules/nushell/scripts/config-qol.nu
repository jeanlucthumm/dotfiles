# QoL config - depends on eza, ripgrep, fzf, fd, carapace

alias lss = ls

# Always make bypass-permissions mode available as a selectable option
def claude --wrapped [...rest] {
  ^claude --allow-dangerously-skip-permissions ...$rest
}

def ls --wrapped [...rest]: [nothing -> string] {
  ^eza -s name --group-directories-first -1 --icons=always ...$rest
}

# Prefer repo-local OpenCode config when present.
def opencode --wrapped [...rest] {
  let config_dir = (try {
    ^git rev-parse --show-toplevel err> /dev/null | str trim
  } catch {
    $env.PWD
  })
  let local_config = ($config_dir | path join "opencode.local.json")

  if ($local_config | path exists) {
    with-env { OPENCODE_CONFIG: $local_config } { ^opencode ...$rest }
  } else {
    ^opencode ...$rest
  }
}

# rg wrapper
def nrg [pattern: string]: [nothing -> table<file: string, line: int, text: string>] {
  # rg exits 1 on no matches and 2 on any error, even one unreadable file
  # among matches. Keep the matches; rg's stderr still reaches the terminal.
  do -i { rg --json $pattern } |
    from json --objects |
    where type == "match" |
    select data.path.text data.line_number data.lines.text |
    rename file line text
}

# Launch Claude Code in ~/nix with a query for AI-enabled config updates
def nmod [query: string]: [nothing -> nothing] {
  cd ~/nix
  claude --permission-mode acceptEdits $query
}

# Claude Code review - optionally pass args to /review command (e.g. "from branch-a to branch-b")
def ccreview [...args: string]: [nothing -> nothing] {
  let review_arg = if ($args | is-empty) { "/review" } else { $"/review ($args | str join ' ')" }
  claude --allowedTools 'Bash(gh pr:*)' -- $review_arg
}

# Carapace completer with path fallback
# Returns null when empty so nushell falls back to file completion
$env.PATH = ($env.PATH | split row (char esep) | prepend "~/.config/carapace/bin")

# $place.command has aliases expanded
let carapace_completer = {|place|
  carapace $place.command.0 nushell ...$place.command
  | from json
  | if ($in | is-empty) { null } else { $in }
}

# Add to existing config (order-independent)
$env.config.completions.external.enable = true
$env.config.completions.external.completer = $carapace_completer

$env.config.keybindings ++= [
  {
    name: fzf_file
    modifier: control
    keycode: char_f
    mode: [emacs, vi_normal, vi_insert]
    event: {
      send: executehostcommand
      cmd: "commandline edit --insert (fd --type f --type d --hidden | fzf | str trim)"
    }
  }
]

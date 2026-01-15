# QoL config - depends on eza, ripgrep, fzf, fd, carapace

alias lss = ls

def ls --wrapped [...rest]: [nothing -> string] {
  ^eza -s name --group-directories-first -1 --icons=always ...$rest
}

# rg wrapper
def nrg [pattern: string]: [nothing -> table<file: string, line: int, text: string>] {
  $'[(rg --json $pattern)]' |
    from json |
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

let carapace_completer = {|spans|
  let expanded_alias = (scope aliases | where name == $spans.0 | $in.0?.expansion?)
  let spans = (if $expanded_alias != null {
    $spans | skip 1 | prepend ($expanded_alias | split row " " | take 1)
  } else { $spans })

  carapace $spans.0 nushell ...$spans
  | from json
  | if ($in | is-empty) { null } else { $in }
}

# Merge into existing config
$env.config = ($env.config | merge {
  completions: {
    external: {
      enable: true
      completer: $carapace_completer
    }
  }
  keybindings: ($env.config.keybindings | append [
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
  ])
})

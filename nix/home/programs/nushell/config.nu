# Helper for ipv4 address
def ipv4 [iface: string]: [nothing -> string] {
  sys net | where name == $iface | get 0.ip | where protocol == "ipv4" | get 0.address
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

# Preview current color config with colored swatches
def color-config []: [nothing -> list<string>] {
  $env.config.color_config | transpose key value | each { |row|
    let color = if ($row.value | describe) == "string" { $row.value } else { $row.value.fg? | default "white" }
    $"(ansi -e {fg: $color})██ ($row.key)(ansi reset)"
  }
}

alias lss = ls

def ls --wrapped [...rest]: [nothing -> string] {
  ^eza -s name --group-directories-first -1 --icons=always ...$rest
}

def ssh --wrapped [...rest] {
  with-env { TERM: xterm-256color } { ^ssh ...$rest }
}

# Concatenate file contents with labels.
def label-files []: [list<path> -> string] {
  each { |file|
    let ext = ($file | path parse | get extension)
    $"Contents of ($file):\n```($ext)\n(open $file --raw | str trim)\n```\n\n"
  } |
  str join
}

# Takes git diff output and wraps it in a code block with diff syntax highlighting.
def label-diff []: [string -> string] {
  $"```diff\n($in)\n```"
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

# Launch Claude Code in ~/nix with a query for AI-enabled config updates
def nmod [query: string]: [nothing -> nothing] {
  cd ~/nix
  # Original with allowedTools flag (commented out - Claude Code won't take the query if this flag is present for some reason)
  # claude --permission-mode acceptEdits --allowedTools "List Read Bash(find:*)" $query
  claude --permission-mode acceptEdits $query
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
  completions: {
    external: {
      enable: true
      completer: $carapace_completer
    }
  }
  keybindings: [
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

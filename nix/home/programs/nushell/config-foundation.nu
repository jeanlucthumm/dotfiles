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

# Preview current color config with colored swatches
def color-config []: [nothing -> list<string>] {
  $env.config.color_config | transpose key value | each { |row|
    let color = if ($row.value | describe) == "string" { $row.value } else { $row.value.fg? | default "white" }
    $"(ansi -e {fg: $color})██ ($row.key)(ansi reset)"
  }
}

$env.config = {
  edit_mode: "emacs"
  hooks: {
    env_change: {
      # Auto-load .nu-local.nu overlay when entering a directory, hide it when leaving
      PWD: [
        {
          condition: {|_, after| ($after | path join ".nu-local.nu" | path exists) }
          code: "overlay use .nu-local.nu"
        }
        {
          condition: {|before, _| (
            $before != null and
            ($before | path join ".nu-local.nu" | path exists) and
            "nu-local" in (overlay list | get name)
          )}
          code: "overlay hide nu-local --keep-env [ PWD ]"
        }
      ]
    }
  }
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
  ]
}

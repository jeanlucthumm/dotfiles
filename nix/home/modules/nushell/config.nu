def gda [] { git add -A; git d }
def yda [] { yadm add -u -p; yadm d }
def gm [msg: string] { git commit -m $msg }
def ym [msg: string] { yadm commit -m $msg }

alias __ls = ls
def ls [...args] {
    if ($args | is-empty) {
        __ls | sort-by type
    } else {
        __ls ...$args | sort-by type
    }
}

alias __ssh = ssh
def ssh [...args] {
    if ($args | is-empty) {
        __ssh
    } else {
        with-env { TERM: xterm-256color } { __ssh ...$args }
    }
}

# Concatenate file contents with labels.
def label-files [] {
  each { |file|
    $"Contents of ($file):\n```\n(open $file --raw | str trim)\n```\n\n"
  } |
  str join
}

# Copy piped in contents to clipboard.
def clip [] {
  if ($env | get -i TMUX | is-not-empty) {
    tmux loadb -
  } else if ($nu.os-info.name == "linux") {
    if ($env.XDG_SESSION_TYPE == "wayland") {
      wl-copy
    } else {
      xclip -selection clipboard
    }
  } else if ($nu.os-info.name == "macos") {
    pbcopy
  } else {
    echo "Unsupported OS"
  }
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
  ]
}

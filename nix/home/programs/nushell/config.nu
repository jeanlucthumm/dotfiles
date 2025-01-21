alias __ls = ls

# ls wrapper with pretty output
def ls [
    --all (-a),         # Show hidden files
    --long (-l),        # Get all available columns for each entry (slower; columns are platform-dependent)
    --short-names (-s), # Only print the file names, and not the path
    --full-paths (-f),  # display paths as absolute paths
    --du (-d),          # Display the apparent directory size ("disk usage") in place of the directory metadata size
    --directory (-D),   # List the specified directory itself instead of its contents
    --mime-type (-m),   # Show mime-type in type column instead of 'file' (based on filenames only; files' contents are not examined)
    --threads (-t),     # Use multiple threads to list contents. Output will be non-deterministic.
    ...pattern: glob,   # The glob pattern to use.
]: [ nothing -> string ] {
    let pattern = if ($pattern | is-empty) { [ '.' ] } else { $pattern }
    (__ls
        --all=$all
        --long=$long
        --short-names=$short_names
        --full-paths=$full_paths
        --du=$du
        --directory=$directory
        --mime-type=$mime_type
        --threads=$threads
        ...$pattern
    ) | sort-by -i type name | grid -c -i -s "\n"
}

# ls wrapper with table output
def lss [
    --all (-a),         # Show hidden files
    --long (-l),        # Get all available columns for each entry (slower; columns are platform-dependent)
    --short-names (-s), # Only print the file names, and not the path
    --full-paths (-f),  # display paths as absolute paths
    --du (-d),          # Display the apparent directory size ("disk usage") in place of the directory metadata size
    --directory (-D),   # List the specified directory itself instead of its contents
    --mime-type (-m),   # Show mime-type in type column instead of 'file' (based on filenames only; files' contents are not examined)
    --threads (-t),     # Use multiple threads to list contents. Output will be non-deterministic.
    ...pattern: glob,   # The glob pattern to use.
]: [ nothing -> table ] {
    let pattern = if ($pattern | is-empty) { [ '.' ] } else { $pattern }
    (__ls
        --all=$all
        --long=$long
        --short-names=$short_names
        --full-paths=$full_paths
        --du=$du
        --directory=$directory
        --mime-type=$mime_type
        --threads=$threads
        ...$pattern
    ) | sort-by -i type name
}

def ssh --wrapped [...rest]: [nothing -> nothing] {
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

# Git status
def ngit-status []: [nothing -> table<status: string, file: string>] {
  git status --porcelain | from ssv -m 1 -n | rename status file
}

# Copy piped in contents to clipboard.
def clip []: [string -> nothing] {
  if ($env | get -i TMUX | is-not-empty) {
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

# Takes git diff output and wraps it in a code block with diff syntax highlighting.
def label-diff []: [string -> string] {
  $"```diff\n($in)\n```"
}

# See https://github.com/nushell/nushell/issues/5552#issuecomment-2113935091
let abbreviations = {
  gt: 'git tree'
  gs: 'git status'
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
    # Hack for fish-like abbreviations
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
  ]
    # End of hack
  menus: [
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

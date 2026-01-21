# Dev config - abbreviations for git, yadm, taskwarrior

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

# Add abbreviation keybindings and menu (order-independent)
$env.config.keybindings ++= [
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

$env.config.menus ++= [
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

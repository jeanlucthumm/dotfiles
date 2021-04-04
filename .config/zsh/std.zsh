#!/bin/bash
### Setup
if [[ $(uname -s) == "Darwin" ]]; then
  OS="mac"
elif [[ $(uname -s) == "Linux" ]]; then
  OS=$(cat /etc/os-release | awk -F '=' '/^ID=.*/ {print $2}')
fi

### Vars
CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}
GITHUB="https://www.github.com/jeanlucthumm/"
CODE="$HOME/Code"

# Oh My ZSH
export ZSH=$CONFIG/zsh/oh-my-zsh
ZSH_THEME="robbyrussell"
HYPHEN_INSENSITIVE="true"
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
plugins=(git fzf)
source $ZSH/oh-my-zsh.sh

importIfExists "$HOME/.cargo/env"

### Alias
alias so="source $ZDOTDIR/.zshrc"
alias zshconfig="$EDITOR $CONFIG/zsh/std.zsh"
alias dim="xrandr --output DVI-I-1 --brightness 0.5"
alias undim="xrandr --output DVI-I-1 --brightness 1.0"
alias capt="maim -s -u $HOME/media/capt.png"
alias cdf='cd $(fd -t d . ~ | fzf)'

### Default overrides
alias pacman="yay"
alias vim="nvim"
alias cat="bat"
alias ls="exa"

if [[ $TERM == xterm-kitty ]]; then
  alias icat="kitty +kitten icat"
  alias newterm='kitty --detach --directory $(pwd)'
fi
if pgrep -x "i3" > /dev/null; then
  alias i3config="$EDITOR $CONFIG/i3/config"
  alias picomconfig="$EDITOR $CONFIG/picom.conf"
fi
if pgrep -x "sway" &> /dev/null; then
  alias i3config="$EDITOR $CONFIG/sway/config"
fi


### Functions
if [[ $OS == "arch" ]]; then
  function refresh_mirror_list () {
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup;
    curl -s "https://www.archlinux.org/mirrorlist/?country=US&protocol=https&use_mirror_status=on" | \
      sed -e 's/^#Server/Server/' -e '/^#/d' | \
      rankmirrors -n 5 > /etc/pacman.d/mirrorlist;
  }
fi

function cdv () {
  if [[ $# == 0 ]]; then
    cd "$CODE"
  else
    cd "$CODE/$1"
  fi
}

# Useful way to come back to something you're working on later
function work () {
  local path_file="$CONFIG/work_path.txt"
  if [[ $# == 0 ]]; then
    if [[ -f $path_file ]]; then
      cd $(cat "$path_file")
    else
      echo "No work path set"
    fi
  else
    echo $(pwd) >| "$path_file"
  fi
}

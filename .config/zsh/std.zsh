#!/bin/bash
### Setup
OS=$(cat /etc/os-release | awk -F '=' '/^ID=.*/ {print $2}')

### Vars
export ZDOTDIR="$HOME/.config/zsh"
export TERMINAL="kitty"
export GITHUB="https://www.github.com/jeanlucthumm/"
export CODE="$HOME/Code"
export PATH="$HOME/.node_modules/bin:$PATH"
export npm_config_prefix="$HOME/.node_modules"
export EDITOR="/bin/vim"
export CC=/usr/bin/clang
export CXX=/usr/bin/clang++
export BAT_THEME="Solarized (light)"

# React Native
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools


### Alias
alias so="source $ZDOTDIR/.zshrc"
alias zshconfig="vim $HOME/.config/zsh/std.zsh"
alias dim="xrandr --output DP-2 --brightness 0.5"
alias undim="xrandr --output DP-2 --brightness 1.0"
alias capt="maim -s -u $HOME/media/capt.png"

### Default overrides
alias pacman="yay"
alias vim="nvim"
alias cat="bat"

if [[ $TERM == xterm-kitty ]]; then
  alias icat="kitty +kitten icat"
  alias newterm='kitty --detach --directory $(pwd)'
fi
if pgrep -x "i3" > /dev/null; then
  alias i3config="vim $HOME/.config/i3/config"
  alias picomconfig="vim $HOME/.config/picom.conf"
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
  local path_file="$HOME/.config/work_path.txt"
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

source $HOME/.config/fish/env.fish

### ===========================================================================
### External

function importIfExists
  if test -e $argv[1]
    source $argv[1]
  end
end

importIfExists $HOME/.cargo/env
importIfExists $CONFIG/fish/google.fish

### ===========================================================================
### Alias

# Default overrides
alias pacman="yay"
alias vim="nvim"
alias cat="bat"
alias ls="exa"

alias so="source $CONFIG/fish/config.fish"
alias fishconfig="$EDITOR $CONFIG/fish/config.fish"
alias dim="xrandr --output DVI-I-1 --brightness 0.5"
alias undim="xrandr --output DVI-I-1 --brightness 1.0"
alias cdf='cd (fd -t d . ~ | fzf)'
alias cdv="cd $CODE"
alias clip="xclip -selection clipboard"
alias sysyadm="sudo yadm -Y /etc/yadm"
alias scli="scli -s"
alias fixkeyb="source $HOME/.xprofile && xmodmap $CONFIG/capsrebind.Xmodmap"
alias venv="source .venv/bin/activate.fish"

if [ $TERM = xterm-kitty ]
  alias icat="kitty +kitten icat"
  alias newterm='kitty --detach --directory (pwd)'
end
if pgrep -x "i3" &> /dev/null
  alias i3config="$EDITOR $CONFIG/i3/config"
  alias picomconfig="$EDITOR $CONFIG/picom.conf"
end
if pgrep -x "sway" &> /dev/null
  alias i3config="$EDITOR $CONFIG/sway/config"
end

### ===========================================================================
### Functions

function work
  set -l dir_file $CONFIG/fish/work_dir_file.txt
  if count $argv &> /dev/null
    echo $argv[1] > $dir_file
  else if test -e $dir_file
    cd (cat $dir_file)
  else
    echo "No work path set."
  end
end

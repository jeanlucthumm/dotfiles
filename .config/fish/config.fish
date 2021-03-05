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
### Alias & Functions

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

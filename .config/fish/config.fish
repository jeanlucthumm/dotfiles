### ===========================================================================
### External

function importIfExists
  set -l file_name $argv[1]
  if test -e $file_name
    if string match "*.fish" $file_name > /dev/null
      source $file_name
    else
      bass $file_name
    end
  end
end

importIfExists $HOME/.cargo/env

### ===========================================================================
### Alias

set -l OS (uname)

if [ "$OS" = "Linux" -a "$DISTRO" = "Arch" ]
  alias pacman="paru"

  alias sysyadm="sudo yadm -Y /etc/yadm"
  alias scli="scli -s"
  alias fixkeyb="source $HOME/.xprofile && xmodmap $CONFIG/capsrebind.Xmodmap"
  alias cp="xcp"

  if [ $TERM = xterm-kitty ]
    alias icat="kitty +kitten icat"
    alias newterm='kitty --detach --directory (pwd)'
  end
  if pgrep -x "i3" > /dev/null
    alias i3config="$EDITOR $CONFIG/i3/config"
    alias picomconfig="$EDITOR $CONFIG/picom.conf"
    alias dim="xrandr --output DP-1 --brightness 0.5"
    alias undim="xrandr --output DP-1 --brightness 1.0"
    alias clip="xclip -selection clipboard"
  end
  if pgrep -x "sway" > /dev/null
    alias i3config="$EDITOR $CONFIG/sway/config"
  end
end


# Default overrides
alias vim="nvim"
alias cat="bat"
alias ls="exa"
alias docker="sudo docker"
alias ssh="TERM=xterm-256color /usr/bin/ssh"

alias so="source $CONFIG/fish/config.fish"
alias fishconfig="$EDITOR $CONFIG/fish/config.fish"
alias cdf='cd (fd -t d . ~ | fzf)'
alias venv="source .venv/bin/activate.fish"
alias g="git"


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

function cdv
  if count $argv &> /dev/null
    if test -e "$CODE/$argv[1]"
      cd "$CODE/$argv[1]"
    else
      cd (fd -1a -t d "$argv[1]" "$CODE")
    end
  else
    cd $CODE
  end
end

function posture
  while true
    if not sleep 5m
      or not notify "Posture"
      return
    end
  end
end

### ===========================================================================
### Shell

bind \ch backward-word
bind \cl forward-word

if [ $OS = "Linux" -a "$DISTRO" = "Arch" ]
  complete -c themer -x -a (themer --list)
end

### ===========================================================================
### Google

importIfExists $CONF/fish/google.fish

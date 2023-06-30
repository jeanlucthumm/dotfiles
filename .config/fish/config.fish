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

if status is-interactive
  if [ "$OS" = "Linux" -a "$DISTRO" = "Arch" ]
    alias pacman="paru"

    alias sysyadm="sudo yadm -Y /etc/yadm"
    alias cp="xcp"
    alias dark="themer solarized-dark"
    alias light="themer solarized-light"

    if pgrep -x "i3" > /dev/null
      alias i3config="$EDITOR $CONF/i3/config##template"
      alias picomconfig="$EDITOR $CONF/picom.conf"
      alias dim="xrandr --output DP-1 --brightness 0.5"
      alias undim="xrandr --output DP-1 --brightness 1.0"
      alias clip="xclip -selection clipboard"
    end
    if pgrep -x "sway" > /dev/null
      alias i3config="$EDITOR $CONF/sway/config"
    end
    alias fixkeyb="source $HOME/.xprofile && xmodmap $CONF/capsrebind.Xmodmap"
  end

  alias done="notify 'done'"

  if [ "$TERM" = "xterm-kitty" ]
    alias icat="kitty +kitten icat"
    alias newterm='kitty --detach --directory (pwd)'
  end


  # Default overrides
  alias vim="nvim"
  alias neov="neovide --multigrid --maximized"
  alias cat="bat"
  alias ls="exa"
  alias docker="sudo docker"
  alias ssh="TERM=xterm-256color /usr/bin/ssh"

  alias cdf='cd (fd -t d . ~ | fzf)'
  alias venv="source .venv/bin/activate.fish"
  alias g="git"
  alias clear-nvim-swap="rm -rf ~/.local/state/nvim/swap"
  alias t="task"
  alias ta="task active"
  alias tr="task ready"
  alias day="timew day"
  alias acc="task end.after:today completed"
  alias fix-tmux-ssh="bass (tmux show-environment -s SSH_AUTH_SOCK)"
end

### ===========================================================================
### Functions

function posture
  while true
    if not sleep 5m
      or not notify "Posture"
      return
    end
  end
end

function i3lock
  timew stop
  /usr/bin/i3lock -c (python3 $CODE/bin/random_hex.py)
  sleep 30m
  xset dpms force off
end

function i3workspace -d "get name of current i3 workspace"
  i3-msg -t get_workspaces | jq -r 'map(select(.focused))[0].name'
end

### ===========================================================================
### Shell

bind \ch backward-word
bind \cl forward-word

if [ $OS = "Linux" -a "$DISTRO" = "Arch" ]
  complete -c themer -x -a (themer --list)
end

if status is-interactive; and is_ssh_session; and not set -q TMUX
  exec tmux attach
end

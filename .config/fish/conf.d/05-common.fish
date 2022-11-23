function generic_install
  if [ "$OS" = "Linux" -a "$DISTRO" = "Arch" ]
    if type -q paru
      paru -S --needed $argv
    else
      sudo pacman -S --needed $argv
    end
  else if [ "$OS" = "Darwin" ]
    brew install $argv
  else
    return 1
  end
end

function clip --description "copy to clipboard"
  if [ "$OS" = "Linux" ]
    if [ "$XDG_SESSION_TYPE" = "x11" ]
      xclip -selection clipboard
    else if [ "$XDG_SESSION_TYPE" = "wayland" ]
      wl-copy
    end
  else if [ "$OS" = "Darwin" ]
    pbcopy
  end
end

function notify --description "send desktop notification"
  if [ "$OS" = "Linux" ]
    notify-send "$argv[1]"
  else if [ "$OS" = "Darwin" ]
    osascript -e "display notification \"$argv[1]\""
  end
end

alias clear-nvim-swap="rm -rf $XDG_DATA_HOME/nvim/swap"

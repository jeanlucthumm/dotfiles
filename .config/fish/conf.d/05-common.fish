function generic_install
  if [ "$OS" = "Linux" -a "$DISTRO" = "Arch" ]
    if type -q yay
      yay -S --needed $argv
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
    xclip -selection clipboard
  else if [ "$OS" = "Darwin" ]
    pbcopy
  end
end

function notify --description "send desktop notification"
  if [ "$OS" = "Linux" -a "$DISTRO" = "Arch" ]
    notify-send "$argv[1]"
  else if [ "$OS" = "Darwin" ]
    osascript -e "display notification \"$argv[1]\""
  end
end

function generic_install
  if [ "$OS" = "Linux" -a -f "/etc/arch-release" ]
    pacman -S --needed $argv
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

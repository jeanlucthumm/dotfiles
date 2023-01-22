function generic_install -a program -d "platform independent package install"
  if [ "$OS" = "Linux" -a "$DISTRO" = "Arch" ]
    if type -q paru
      paru -S --needed $program
    else
      sudo pacman -S --needed $program
    end
  else if [ "$OS" = "Darwin" ]
    brew install $argv
  else
    return 1
  end
end

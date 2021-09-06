function generic_install
  if [ "$OS" = "Linux" -a -f "/etc/arch-release" ]
    pacman -S --needed $argv
  else if [ "$OS" = "Darwin" ]
    brew install $argv
  else
    return 1
  end
end

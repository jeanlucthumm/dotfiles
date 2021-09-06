#!/bin/fish
#
# Bootstrap script for yadm

# File containing a list of steps already executed.
# This avoid doing the same thing twice if we call bootstrap multiple times
set STEP_FILE $CONFIG/yadm/steps.txt

set LOG "-->"

# Read all finished steps into $STEPS
if test -e $STEP_FILE
  /usr/bin/cat $STEP_FILE | read -za STEPS
else
  touch $STEP_FILE
end

if not contains "YAY" $STEPS
  and [ "$DISTRO" = "Arch" ]
  echo $LOG "Setting up yay"

  /usr/bin/pacman -S --needed git base-devel
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si
  cd ..
  rm -rf yay

  echo "YAY" >> $STEP_FILE
end


if not contains "INIT" $STEPS
  echo $LOG "Setting up initial programs"

  echo "Select installation type: "
  echo \t1. Minimal
  echo \t2. Arch + GUI
  read -l -P "(1/2): " resp

  switch $resp
    case 1
      /usr/bin/cat "$CONF/yadm/term_progs.txt" | read -za PROGS
    case 2
      /usr/bin/cat "$CONF/progs.txt" | read -za PROGS
    case '*'
      echo "Uknown option: $resp"
      exit 1
  end

  if not generic_install $PROGS
    exit 1
  end

  echo "INIT" >> $STEP_FILE
end

if not contains "NVIM" $STEPS
  echo $LOG "Setting up neovim"

  git clone --depth=1 "https://github.com/savq/paq-nvim.git" \
    $XDG_DATA_HOME/nvim/site/pack/paqs/start/paq-nvim

  nvim +PaqInstall +qa!

  echo "NVIM" >> $STEP_FILE
end

if not contains "FISH" $STEPS
  echo $LOG "Setting up fish"

  curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
  fisher update

  echo "FISH" >> $STEP_FILE
end

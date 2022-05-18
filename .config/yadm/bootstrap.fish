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

if not contains "PARU" $STEPS
  and [ "$DISTRO" = "Arch" ]
  echo $LOG "Setting up paru"

  generic_install clang
  and sudo /usr/bin/pacman -S --needed git base-devel
  and git clone https://aur.archlinux.org/paru.git
  and cd paru
  and makepkg -si
  and cd ..
  and rm -rf paru

  and echo "PARU" >> $STEP_FILE
end

if not contains "RUST" $STEPS
  echo $LOG "Setting up Rust"

  sudo /usr/bin/pacman -S --needed rustup
  and rustup default stable

  and echo "RUST" >> $STEP_FILE
end

if not contains "INIT" $STEPS
  echo $LOG "Setting up initial programs"
  echo "Select installation type: "
  echo \t1. Minimal
  echo \t2. Arch + GUI
  read -l -P "(1/2): " resp

  and switch $resp
    case 1
      /usr/bin/cat "$CONF/yadm/term_progs.txt" | read -za PROGS
    case 2
      /usr/bin/cat "$CONF/progs.txt" | read -za PROGS
    case '*'
      echo "Uknown option: $resp"
      exit 1
  end

  and echo $PROGS
  and generic_install $PROGS

  and echo "INIT" >> $STEP_FILE
end

if not contains "FISH" $STEPS
  echo $LOG "Setting up fish"

  curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
  and fisher update

  and echo "FISH" >> $STEP_FILE
end

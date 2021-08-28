#!/bin/fish
#
# Bootstrap script for yadm

source $HOME/.config/fish/env.fish

# Required programs for bootstrap to suceed.
set REQUIRED yarn nvim fish git
# File containing a list of steps already executed.
# This avoid doing the same thing twice if we call bootstrap multiple times
set STEP_FILE $CONFIG/yadm/steps.txt


set LOG "-->"

function check_programs
  for prog in $argv
    if not command -v $prog > /dev/null
      set missing $missing $prog
    end
  end
  if test (count $missing) -ne 0
    echo "Bootstrap needs the following programs to succeed:"
    for m in $missing
      echo $m
    end
    return 1
  end
  return 0
end

if not check_programs $REQUIRED
  exit
end

# Read all finished steps into $STEPS
if test -e $STEP_FILE
  cat $STEP_FILE | read -za STEPS
else
  touch $STEP_FILE
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

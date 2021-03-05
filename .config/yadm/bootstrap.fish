#!/bin/fish
#
# Bootstrap script for yadm


# Required programs for bootstrap to suceed.
set REQUIRED yarn curl nvim
# File containing a list of steps already executed.
# This avoid doing the same thing twice if we call bootstrap multiple times
set STEP_FILE $HOME/.config/yadm/steps.txt


set LOG "-->"

function check_programs
  for prog in $argv
    if not command -v $prog &> /dev/null
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

  sh -c 'curl -fLo $XDG_DATA_HOME/nvim/site/autoload/plug.vim --create-dirs \
         https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  nvim +'PlugInstall --sync' +qa

  echo "NVIM" >> $STEP_FILE
end

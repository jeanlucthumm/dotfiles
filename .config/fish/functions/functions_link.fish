# Workaround for https://github.com/fish-shell/fish-shell/issues/1819
#
# Fish won't source function defs within folders in the functions directory.
# From an organizatinal perspective, this sucks, so we have a util function
# that will sym link stuff out of folders

function functions_link -d "Sym link nested function fish function defs so that they work"
  set functions_dir ~/.config/fish/functions
  if not test -d $functions_dir
      echo "Functions directory not found: $functions_dir"
      exit 1
  end

  # Iterate over each subdirectory in the functions directory
  for subdir in $functions_dir/*
      # Check if it's a directory
      if test -d $subdir
          # Iterate over each file in the subdirectory
          for file in $subdir/*
              echo "Linking $file"
              # Create a symbolic link in the functions directory
              # The basename command extracts the filename from the path
              ln -sf $file $functions_dir/(basename $file)
          end
      end
  end
end

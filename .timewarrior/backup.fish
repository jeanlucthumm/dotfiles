#!/bin/fish
set -l DIR ~/.timewarrior
for file in ~/.timewarrior/data/2*.data
  echo "Backing up $file..."
  cat $file | python3 ~/.timewarrior/backup-google.py > ~/.timewarrior/google/(basename $file)
end

set -l totalCount (cat ~/.timewarrior/google/2*.data | wc -l)
echo >~/.timewarrior/google/tags.data "\
{
  \"google\":{\"count\":$totalCount}
}"

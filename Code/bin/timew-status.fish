#!/bin/fish
if timew &> /dev/null
  set -l tag (timew export from yesterday | jq -r '.[length-1].tags[0]')
  set -l timer (timew | tail -n 1 | string match -r '(\d?\d:\d\d):\d\d$')
  echo "☑ $tag $timer[2]"
else
  echo "☑ none"
end

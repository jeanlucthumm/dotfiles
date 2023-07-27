#!/bin/fish
if timew &> /dev/null
  set -l tag (timew export @1 | jq -r '.[0].tags[0]')
  set -l timer (timew | tail -n 1 | string match -r '(\d?\d:\d\d):\d\d$')
  echo "☑ $tag $timer[2]"
else
  echo "☑ none"
end

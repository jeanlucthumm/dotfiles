#!/bin/fish
if timew &> /dev/null
  set -l tag (timew export from yesterday | jq -r '.[length-1].tags[0]')
  set -l timer (timew | tail -n 1 | string match -r '(\d?\d:\d\d):\d\d$')
  set -l taskout (task +ACTIVE export | jq -r '.[0].description')
  if [ $taskout = null ]
    $taskout = ""
  end
  echo "$taskout ☑ $tag $timer[2]"
else
  echo "☑ none"
end

#!/bin/fish
set msg (timew)
if string match -q '*no active*' $msg
  echo "☑ none"
else
  set -l tag (echo $msg | string split " " -f 2)
  set -l timer (echo $msg | string match -r '(\d?\d:\d\d):\d\d$')
  echo "☑ $tag $timer[2]"
end

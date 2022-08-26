#!/bin/fish
function battery
  string match -r '^.*:\s(.*),\s([0-9]+%).*' (acpi -b) | read -l -L out charging percent
  set -l charging_icon ""
  if [ "$charging" = "Charging" ]
    set charging_icon "🔋"
  end
  echo "$charging_icon$percent"
end

function print_status_line
  set -l date (date +'%Y-%m-%d %l:%M:%S %p')
  and echo (battery)" | $date"
end

while print_status_line
  sleep 1
end


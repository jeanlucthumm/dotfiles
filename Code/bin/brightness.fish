#!/bin/fish
set -l device /sys/class/backlight/intel_backlight
set -l brightness $device/brightness
set -l max $device/max_brightness
switch $argv[1]
  case down
    echo (math (cat $brightness) - $argv[2]) > $brightness
  case up
    echo (math (cat $brightness) + $argv[2]) > $brightness
  case value
    cat $brightness
  case max
    cat $max
  case '*'
    echo "Invalid use"; return -1
end

#!/bin/bash
xrandr --output "HDMI-0" --mode 2560x1440 --rate 144.00 \
	--output "DP-2" --off
feh --auto-rotate --bg-scale $HOME/media/wallpapers/low-poly-mountains.jpg

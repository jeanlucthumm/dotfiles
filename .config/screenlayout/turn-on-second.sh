#!/bin/sh
xrandr --output DVI-D-0 --off \
	--output HDMI-0 --mode 2560x1440 --rate 144.0 --pos 0x649 --rotate normal \
	--output HDMI-1 --off \
	--output DP-0 --off \
	--output DP-1 --off \
	--output DP-2 --mode 2560x1440 --pos 2560x0 --rotate left \
	--output DP-3 --off
feh --auto-rotate --bg-scale $HOME/media/wallpapers/low-poly-mountains.jpg --bg-scale $HOME/media/wallpapers/vertical-forest.jpg

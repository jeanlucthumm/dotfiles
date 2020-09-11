#!/bin/bash
VOL=`pamixer --get-volume`

echo "♪ $VOL%"	# full_text
echo "♪"		# short_text
echo \#`$HOME/bin/color-mid $1 $2 $VOL`

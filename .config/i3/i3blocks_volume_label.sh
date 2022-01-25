#!/bin/bash
VOL=`pactl list sinks | grep Volume | head -n1 | awk '{print $5}'`

echo "♪ $VOL"	# full_text

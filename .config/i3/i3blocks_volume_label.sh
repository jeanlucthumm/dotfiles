#!/bin/bash
SINK=`pactl get-default-sink`
VOL=`pactl get-sink-volume $SINK | grep -o -E '[[:digit:]]+%' | head -n 1`

echo "♪ $VOL"	# full_text

#!/bin/bash
DEVICE=$(ratbagctl list | awk -F ':' 'NR==1{print $1}')

if [[ $(ratbagctl $DEVICE name) != *"Gaming Mouse"* ]]; then
	echo "Could not find Logitech gaming mouse to set profile"
	exit 1
fi

ratbagctl "$DEVICE" dpi set 1400

xset r rate 150 80
xset b off
xrdb -merge /home/jeanluc/.Xresources
# Required for Dunst to work
systemctl --user import-environment DISPLAY
exec i3

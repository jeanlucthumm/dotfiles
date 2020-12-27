xset r rate 150 60
xset b off
# Required for Dunst to work
systemctl --user import-environment DISPLAY
exec i3

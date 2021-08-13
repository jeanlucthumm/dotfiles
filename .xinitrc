# Tune keyboard delay and repeat
xset r rate 150 80

# Turn annoying bell off
xset b off

# Integrate custom Xresources which define colors and other things for some apps
xrdb -merge /home/jeanluc/.Xresources

# Keyring daemon. Works with ssh-add across all terminal sessions
eval $(/usr/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)
export SSH_AUTH_SOCK

# Lets services accesss the X session (maybe, dunno if it works)
systemctl --user import-environment DISPLAY

# Start the WM
exec i3

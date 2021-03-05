xset r rate 150 80
xset b off
xrdb -merge /home/jeanluc/.Xresources
# Required for Dunst to work
eval $(/usr/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)
export SSH_AUTH_SOCK
systemctl --user import-environment DISPLAY
exec i3

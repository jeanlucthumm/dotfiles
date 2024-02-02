function clip -d "copy to clipboard"
  if set -q TMUX
    tmux loadb -
  else if [ "$OS" = "Linux" ]
    if [ "$XDG_SESSION_TYPE" = "x11" ]
      xclip -selection clipboard
    else if [ "$XDG_SESSION_TYPE" = "wayland" ]
      wl-copy
    end
  else if [ "$OS" = "Darwin" ]
    pbcopy
  end
end

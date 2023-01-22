function notify -a msg -d "send desktop notification"
  if [ "$OS" = "Linux" ]
    notify-send "$msg"
  else if [ "$OS" = "Darwin" ]
    osascript -e "display notification \"$msg\""
  end
end

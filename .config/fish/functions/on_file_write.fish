function on_file_write -a watch -a command -d "run command on writes to watch"
  while inotifywait --quiet --event close_write $watch
    $command
  end
end

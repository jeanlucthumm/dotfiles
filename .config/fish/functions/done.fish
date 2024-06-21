function done -d "Notify with the result of previous command"
  set -l stat $status
  set -l message ""
  if test $stat -eq 0
    set message "Done"
  else
    set message "Failed"
  end
  notify $message
end

function ts -d "Stop this task and make another one active" -a new_task
  set -l tmpfile "/tmp/toggle_last_id"
  task +ACTIVE export | jq '.[0].id' | read -l active_id
  echo "Active task is $active_id"

  set -l new_id $new_task
  if [ "$new_task" = "" ]
    if [ -e "$tmpfile" ]
      cat $tmpfile | read -L new_id
    else
      echo "No previous id"
      return 1
    end
  end

  echo "$active_id" > $tmpfile
  task stop $active_id
  task start $new_id
end

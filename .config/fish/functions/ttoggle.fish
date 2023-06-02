function ttoggle -d "Stop this task and make another one active" -a new_task
  task +ACTIVE export | jq '.[0].id' | read -l active_id
  task stop $active_id
  task start $new_task
end

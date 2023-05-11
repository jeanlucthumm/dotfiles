function tbreak -d "Break down active task further" -a description
  task +ACTIVE export | jq '.[0].id' | read -l active_id
  task +ACTIVE export | jq '.[0].project' | read -l active_project
  task add proj:$active_project "$description" blocks:$active_id
  task export newest | jq '.[0].id' | read -l new_id
  task stop $active_id
  task start $new_id
end

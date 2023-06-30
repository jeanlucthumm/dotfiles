function tparent -d "Finish current task and start parent task"
  set -l active_id (task +ACTIVE export | jq '.[0].id')
  set -l uuid (task +ACTIVE export | jq '.[0].uuid')
  task $active_id done
  # Query after done since ids change
  set -l parent_id (task export | jq ".[] | select(.depends | index($uuid)) | .id")
  task $parent_id start
end

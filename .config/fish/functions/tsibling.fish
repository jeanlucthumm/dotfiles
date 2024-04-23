function tsibling -d "New task as child of current parent" -a description
  task +ACTIVE export | jq -r '.[0].uuid' | read -l active_id
  # Find the parent task
  task +PENDING export | jq -r --arg UUID $active_id 'limit(1; .[] | select(.depends[]? == $UUID) | .id)' | read -l parent_id
  echo "tchild $parent_id $description"
end

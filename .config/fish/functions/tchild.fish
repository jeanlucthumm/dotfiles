function tchild -d "Add a child to a task while inheriting relevant attributes" -a parent_id -a desc
  set -l pjson (task $parent_id export | jq '.[0]')
  echo $pjson | jq -r 'keys[]' | read -za keys

  set -l skip_keys "id" "description" "entry" "modified" "status" "uuid" "urgency" "depends" "start" 

  set -l args $desc
  for key in $keys
    if contains $key $skip_keys
      continue
    end
    set args $args "$key:"(echo $pjson | jq -r ".$key")
  end

  set args $args "blocks:$parent_id"
  task add $args
end

function tchild -d "Add a child to a task while inheriting relevant attributes" -a parent_id -a desc
  set -l pjson (task $parent_id export | jq '.[0]')
  set -l due (echo $pjson | jq '.due')
  set -l priority (echo $pjson | jq '.priority')
  set -l project (echo $pjson | jq '.project')

  set -l args $desc
  if [ "$due" != "null" ]
    set args $args "due:$due"
  end
  if [ "$priority" != "null" ]
    set args $args "priority:$priority"
  end
  if [ "$project" != "null" ]
    set args $args "project:$project"
  end
  set args $args "blocks:$parent_id"
  task add $args
end

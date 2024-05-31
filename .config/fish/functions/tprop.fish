function tprop -d "Get properties of active task"
  task +ACTIVE export | jq -r ".[0].$argv[1]"
end

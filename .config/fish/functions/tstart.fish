function tstart -d "Start the next available task"
  task (task export ready | jq -r '.[0].id') start
end

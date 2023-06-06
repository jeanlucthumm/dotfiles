function acc -d "Taskwarrior report on today's accomplishments"
  task end.after:(date -I) completed
end

# Parses timew data files
def from-timew []: [string -> table] {
  $in |
  lines |
  parse "inc {start} - {stop} # {name}" |
  str trim |
  update start { into datetime } |
  update stop { into datetime }
}

# Computes interval durations
def durations []: [table -> table] {
  each { |row| $row.stop - $row.start }
}

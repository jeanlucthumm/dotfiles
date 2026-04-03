# Nushell wrapper for gh
def ngh [] {}

# Nushell wrapper for gh pr
def "ngh pr" [] {}

# GitHub PR checks
def "ngh pr checks" [
  --failed (-f)  # Show only failed checks
]: [nothing -> table<name: string, link: string, state: string>] {
  let checks = gh pr checks --json name,link,state | from json | select name state link
  if $failed {
    $checks | where state == "FAILURE"
  } else {
    $checks
  }
}

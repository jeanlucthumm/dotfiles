# Nushell wrapper for gh
def ngh [] {}

# Nushell wrapper for gh pr
def "ngh pr" [] {}

# GitHub PR checks
def "ngh pr checks" []: [nothing -> table<name: string, link: string, state: string>] {
  gh pr checks --json name,link,state | from json
}

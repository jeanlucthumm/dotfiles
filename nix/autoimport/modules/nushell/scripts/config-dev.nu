# Dev config - abbreviations for git, yadm, taskwarrior
# Expand on space or enter in command position, never inside strings or
# external command arguments.
$env.config.abbreviations = {
  g: 'git'
  tre: 'git tree'
  gs: 'git status'
  gd: 'git d'
  ge: 'git de'
  gm: 'git commit -m'
  ga: 'git add -A'
  gda: 'git add -A; git d'
  gl: 'gt log'
  gwl: 'git worktree list'
  yda: 'yadm add -u -p; yadm d'
  ym: 'yadm commit -m'
  tr: 'task ready'
  ta: 'task active'
}

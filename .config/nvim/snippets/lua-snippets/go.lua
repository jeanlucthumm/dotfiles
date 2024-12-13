-- Snippets for Golang
return {
  -- "log.Infof("DEBUG DEBUG {1}: %v", {2})"
  s('ldebug', {
    t('log.Infof("DEBUG DEBUG '),
    i(1),
    t(': %v", '),
    i(2),
    t(')'),
  }),
  -- if err != nil { ... }
  s('ierr', {
    t('if err != nil {', '\t'),
    i(0),
    t('}'),
  }),
}

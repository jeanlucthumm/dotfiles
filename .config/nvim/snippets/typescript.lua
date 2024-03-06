-- Snippets for Typescript
return {
  -- "console.log("DEBUG DEBUG", {1})"
  s('clog', {
    t('console.log("DEBUG DEBUG", '),
    i(1),
    t(');'),
  }),
}

-- Snippets for Markdown: Claude Code SKILL.md authoring.
-- `skill` scaffolds the frontmatter and is auto-expanded for new SKILL.md
-- files (see the SkillTemplate autocmd in init.lua). The `sk-*` snippets
-- cover every optional frontmatter key; type `sk` to see them all in the
-- completion menu. <C-l> cycles choice nodes (model, effort, ...).
-- Each sk-* snippet ends with a newline so keys stack cleanly above `---`.

local function skill_dir()
  return vim.fn.expand('%:p:h:t')
end

return {
  s({ trig = 'skill', dscr = 'SKILL.md frontmatter scaffold' }, {
    t({ '---', 'name: ' }),
    f(skill_dir),
    t({ '', 'description: ' }),
    i(1, 'What it does, concrete trigger phrases, and what it is NOT for.'),
    t({ '', '' }),
    i(2), -- extra frontmatter keys go here (sk-* snippets)
    t({ '---', '', '# ' }),
    f(skill_dir),
    t({ '', '', '' }),
    i(0),
  }),

  -- Optional frontmatter keys, one snippet per key
  s({ trig = 'sk-when', dscr = 'when_to_use: extra trigger phrases (appended to description)' },
    { t('when_to_use: '), i(1), t({ '', '' }) }),
  s({ trig = 'sk-hint', dscr = 'argument-hint: autocomplete hint for /name' },
    { t('argument-hint: ['), i(1, 'arg'), t({ ']', '' }) }),
  s({ trig = 'sk-args', dscr = 'arguments: named positional args for $name substitution' },
    { t('arguments: '), i(1, 'name'), t({ '', '' }) }),
  s({ trig = 'sk-noauto', dscr = 'disable-model-invocation: user-only skill, no auto-fire' },
    { t({ 'disable-model-invocation: true', '' }) }),
  s({ trig = 'sk-hidden', dscr = 'user-invocable: false — hidden from / menu, Claude-only' },
    { t({ 'user-invocable: false', '' }) }),
  s({ trig = 'sk-tools', dscr = 'allowed-tools: pre-approved tools for the invoking turn' },
    { t('allowed-tools: '), i(1, 'Bash(jj *), Read'), t({ '', '' }) }),
  s({ trig = 'sk-notools', dscr = 'disallowed-tools: removed from pool while skill is active' },
    { t('disallowed-tools: '), i(1), t({ '', '' }) }),
  s({ trig = 'sk-model', dscr = 'model: override for the turn' },
    { t('model: '), c(1, { t('inherit'), t('opus'), t('sonnet'), t('haiku'), i(nil, 'claude-...') }), t({ '', '' }) }),
  s({ trig = 'sk-effort', dscr = 'effort: reasoning effort override' },
    { t('effort: '), c(1, { t('medium'), t('low'), t('high'), t('xhigh'), t('max') }), t({ '', '' }) }),
  s({ trig = 'sk-fork', dscr = 'context: fork — run in a subagent (agent + background)' }, {
    t({ 'context: fork', 'agent: ' }),
    c(1, { t('general-purpose'), t('Explore'), t('Plan'), t('claude') }),
    t({ '', 'background: ' }),
    c(2, { t('true'), t('false') }),
    t({ '', '' }),
  }),
  s({ trig = 'sk-paths', dscr = 'paths: limit auto-invocation to matching files' },
    { t('paths: '), i(1, 'src/**/*.ts'), t({ '', '' }) }),
  s({ trig = 'sk-shell', dscr = 'shell: for !`cmd` injection blocks' },
    { t('shell: '), c(1, { t('bash'), t('powershell') }), t({ '', '' }) }),
  s({ trig = 'sk-hooks', dscr = 'hooks: skill-scoped lifecycle hooks' }, {
    t({ 'hooks:', '  ' }),
    i(1, 'PostToolUse'),
    t({ ':', "    - matcher: '" }),
    i(2, 'Write|Edit'),
    t({ "'", '      hooks:', '        - type: command', "          command: '" }),
    i(3, 'echo done'),
    t({ "'", '' }),
  }),
  s({ trig = 'sk-meta', dscr = 'metadata: free-form map, ignored by Claude' },
    { t({ 'metadata:', '  ' }), i(1, 'key: value'), t({ '', '' }) }),
  s({ trig = 'sk-license', dscr = 'license: Agent Skills spec field (matters for claude.ai upload)' },
    { t('license: '), i(1, 'MIT'), t({ '', '' }) }),
  s({ trig = 'sk-compat', dscr = 'compatibility: env requirements, <=500 chars (Agent Skills spec)' },
    { t('compatibility: '), i(1), t({ '', '' }) }),
}

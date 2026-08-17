---
name: skill-writing
description: Read BEFORE writing or editing any skill or slash command (SKILL.md in ~/.claude/skills, .agents/skills, .claude/commands, plugin skills). Encodes Jean-Luc's standing rules on how skills must be written.
---

# Writing skills

In Jean-Luc's words:

- Main thing: do not over-prescribe. There's a tendency to try to explain the
  entirety of a process. Realize that it will be YOU who's reading these
  skills. Add just enough guidance to steer, but do not list every little
  thing. Trust the reader's intelligence.
- Corollary of the above: keep everything as terse as possible. Skills pollute
  context and have butterfly effect. The less tokens the better.

Two additions:

- Explain the why, not just the what. A reader who knows the intent can derive
  the steps; a reader with only steps breaks on the first case you didn't
  anticipate.
- The `description` frontmatter is the trigger surface, not a summary. Write
  it for the moment of deciding whether to load the skill: concrete trigger
  phrases, and what it is NOT for when misfires are likely.

## Pointers from hand edits

Generalized guidance distilled from Jean-Luc's hand edits to skills (via
edit-skill). Append the lesson, not the diff; merge into an existing bullet
when one already covers it.

- Skills that only make sense as an explicit user action (slash-command style)
  get `disable-model-invocation: true` in frontmatter.
- No H1 restating the skill name — frontmatter already carries it. Start with
  the point.
- Cut "in case he also wants X" contingency lines; the reader can derive the
  same pattern.

Pre-compaction memory flush. Store durable memories now by updating or creating the files below.

## Memory Structure

All paths under `memory/`. YYYY-MM-DD is substituted with today's date.

### 1. `memory/MEMORY.md` — Living working memory

Update with any durable facts the agent needs to function well in future sessions:

- Active threads/projects and their current state
- User preferences and facts (communication style, interests, tools they use)
- Ongoing commitments or recurring patterns
- Key relationships or people mentioned

This is NOT a log. It's a snapshot of "what matters right now." Organized by topic, not by time.

### 2. `memory/journal/YYYY-MM-DD.md` — Daily life journal

A life record for the user, not for the agent. Append entries capturing:

- What actually happened in their day
- How they seemed to be feeling
- Who they interacted with
- What was notable or memorable
- Read between the lines — infer the human stuff

Write in third person past tense, like a biographer's notes. Not a task log. "Had a long debugging session and seemed frustrated but satisfied when it finally worked" not "Fixed bug in auth module."

You may create journal entries for days without direct conversation if significant events can be reliably inferred from surrounding context. For example, if Monday's conversation references what happened over the weekend, write a weekend entry.

### 3. `memory/cycles/YYYY-MM-DD.md` — Bi-weekly cycle summary

Cycles are Monday-to-Sunday, 2 weeks. Named by the Monday start date. Read the current cycle file first. Only append if meaningful trends have evolved — a new pattern emerging, a thread resolving, a trajectory shift. If nothing has meaningfully changed at this level, skip it.

When you do write, capture:

- Major themes of the period
- Patterns observed (productivity, mood, interests)
- Key decisions made
- Unresolved threads carrying into next cycle

## Guidelines

- Prefer appending to existing files. Overwriting is acceptable when correcting inaccuracies.
- If nothing worth storing, reply with NO_REPLY.
- Be honest about what you can and can't infer — don't fabricate details.

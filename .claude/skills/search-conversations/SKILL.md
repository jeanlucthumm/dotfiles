---
name: search-conversations
description: Full-text search over past Claude Code conversations (the local JSONL transcripts). Use for "did we discuss X", "find that session/conversation about X", or recalling prior work that isn't in memory or ~/memory. NOT for ~/memory project docs (use ~/memory/bm25.py) or for resuming a session by name (/resume).
---

# Search past conversations

There is no built-in transcript search; this skill's `bm25.py` (stdlib-only,
re-indexes on every run) fills the gap. Transcripts live under
`~/.claude/projects/<dir>/`, where `<dir>` is the project cwd with every `/`
and `.` replaced by `-` (e.g. `-Users-jeanlucthumm-nix`).

```
~/.claude/skills/search-conversations/bm25.py <dir> "<query>" [-k N]
```

Pass the project's transcript dir, or `~/.claude/projects` to search every
project (~seconds, still fine). Hits are labeled
`<session>.jsonl [title]:<line> (role)` with a date, so you can follow up by
reading around that line in the file.

Flags, all optional: `--role user|assistant`, `--since YYYY-MM-DD` / `--days N`,
`--context N` (show surrounding messages instead of a snippet), `--full`,
`--max-per-file N` (default 3, diversity cap), `--stats`.

Notes:

- The script already filters harness noise (tool calls, injected CLAUDE.md
  context, system reminders, duplicate history from resumed sessions), so
  results are real conversation text. It also indexes `.md` files it finds.
- The current session pollutes its own results: if the query echoes words
  from this conversation, top hits will be this conversation. Rank lower hits
  accordingly, or filter with `--since`/`--days`.
- The JSONL format is internal to Claude Code and changes between versions.
  If results look broken after an update, suspect the format, and fix
  `clean_message_text()` in the script.

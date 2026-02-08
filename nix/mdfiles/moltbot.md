# Moltbot Setup

## What is Moltbot

[Moltbot](https://github.com/moltbot/moltbot) is a local-first personal AI assistant that integrates with messaging platforms (Telegram, WhatsApp, Signal, etc.). Key features:

- Runs on your own devices via WebSocket gateway
- Multi-channel messaging integration
- Cron jobs, webhooks, file operations
- Tool/skill plugins via ClawdHub
- Recommends Anthropic Pro/Max + Opus 4.5

Install: `npm install -g moltbot@latest && moltbot onboard --install-daemon`

---

## Use Case 1: Chore Automation Queue

**Goal**: Telegram-based task queue where I can add chores, and the bot manages context and can work on them in the background.

### How Moltbot Supports This

| Feature | Status | How |
|---------|--------|-----|
| Chore folders with markdown context | Built-in | Bot has full read/write to workspace (`~/clawd/`) |
| Queue system via Telegram | Built-in | Messages persist in session; bot can update files |
| Context per chore | Built-in | Create `chores/<name>.md` files, bot reads/writes them |
| Persistent storage | Built-in | Workspace files + session transcripts survive restarts |
| Background work on chores | Built-in | Sub-agents via `sessions_spawn` tool |
| Sub-agent asks questions | Config needed | Enable `sessions_send` or use `message` tool |

### Implementation

**Workspace structure:**
```
~/clawd/
├── chores/
│   ├── queue.md        # Active chore list with status markers
│   ├── laundry.md      # Context/history for laundry chore
│   ├── groceries.md    # Context/history for groceries
│   └── ...
├── skills/
│   └── chores/
│       └── SKILL.md    # Teaches bot how to work with chore files
└── memory/
    └── YYYY-MM-DD.md   # Daily notes (auto-created)
```

**Custom skill (`~/clawd/skills/chores/SKILL.md`):**
```markdown
---
name: chores
description: Manage my personal chore queue in the workspace.
---

# Chores System

Chore files live in `~/clawd/chores/`.

## File format
- `queue.md` - active chores with status
- Individual files like `laundry.md` for context/history

## Status markers in queue.md
- `[ ]` - pending
- `[x]` - done
- `[?]` - needs clarification (ask me)
- `[!]` - blocked (note the blocker)

## When I mention a chore
1. Check if it exists in `queue.md`
2. If new, add it with `[ ]` status
3. If it needs context, create/update a dedicated file

## Background work
When asked to work on a chore in background, use `sessions_spawn` to create a sub-agent. The sub-agent should:
1. Read the chore's context file
2. Do the work
3. Update the file with findings
4. Announce results back
```

**Sub-agent config for questions (`moltbot.json`):**
```json5
{
  tools: {
    subagents: {
      tools: {
        // Allow sub-agents to send messages back for questions
        deny: ["sessions_spawn", "sessions_list", "sessions_history"]
      }
    }
  }
}
```

### Usage Examples

- "Add 'fix dryer' to my chores"
- "What's the status of my chores?"
- "Work on the dryer chore in the background and let me know what you find"
- "Mark laundry as done"

---

## Use Case 2: Daily Check-in / Journal

**Goal**: Chat that tracks my day, gives feedback on todos, and I can ask how I'm doing.

**Clarification**: Not proactive outreach - I message it throughout the day and it gives feedback based on context.

### How Moltbot Supports This

| Feature | Status | How |
|---------|--------|-----|
| Session persistence | Built-in | Conversation persists all day (resets 4am default) |
| Auto-timestamp messages | Built-in | Session transcripts have timestamps |
| Todo awareness | Setup needed | `TODO.md` in workspace OR enable a todo skill |
| Calendar awareness | Setup needed | Calendar skill or manual sync to file |
| Feedback on progress | Built-in | Bot has context, just ask "how am I doing?" |
| Auto-journal | Built-in | Conversation IS the log; also `memory/YYYY-MM-DD.md` |
| Daily summary | On-demand | Ask bot to generate and save summary |

### Implementation

**Workspace structure:**
```
~/clawd/
├── TODO.md             # Daily todos - auto-loaded on session start
├── CALENDAR.md         # Today's calendar (manual or synced)
└── memory/
    └── YYYY-MM-DD.md   # Daily notes + summaries
```

**Todo awareness options:**

1. **File-based (simplest)**: Keep `TODO.md` in workspace, update manually or via bot
2. **Apple Reminders**: `moltbot config set skills.entries.apple-reminders.enabled true`
3. **Things 3**: `moltbot config set skills.entries.things-mac.enabled true`
4. **Notion**: Enable `notion` skill + set `NOTION_API_KEY`
5. **Trello**: Enable `trello` skill + set API keys

**Calendar awareness options:**

1. **File-based**: Paste/sync calendar to `CALENDAR.md`
2. **Google Calendar**: Add MCP server or custom skill using `gcalcli`
3. **Apple Calendar**: Custom skill using AppleScript (macOS)

### Usage Examples

- "Here's what I'm working on today: [list]"
- "I finished the report"
- "How am I doing today?"
- "Add a meeting at 2pm"
- "Generate a summary of today and save it"

---

## Key Concepts

### Workspace (`~/clawd/`)
Bot has full read/write access. Auto-loaded files:
- `AGENTS.md` - operating instructions
- `MEMORY.md` - long-term context
- `TODO.md` - if it exists
- `memory/YYYY-MM-DD.md` - today + yesterday

### Skills (`~/clawd/skills/`)
Folders with `SKILL.md` that teach the bot capabilities. Auto-loaded on session start.

### ClawdHub
Public skill registry at https://clawdhub.com
```bash
npm i -g clawdhub
clawdhub search "calendar"
clawdhub install <skill-slug>
```

### Sub-agents
Background agent instances for parallel/long-running work:
- Spawn via `sessions_spawn` tool
- Run in isolated session
- Announce results back to chat
- Manage with `/subagents list|stop|send`

### Memory Search
Semantic search over workspace files:
```json5
// moltbot.json
{
  agents: {
    defaults: {
      memorySearch: {
        enabled: true,
        extraPaths: ["chores"]  // Add custom dirs
      }
    }
  }
}
```

---

## Resources

- NixOS config: [`system/programs/moltbot/`](../system/programs/moltbot/CLAUDE.md) (extra module info)
- [Moltbot GitHub](https://github.com/moltbot/moltbot)
- [Docs](https://docs.molt.bot)
- [ClawdHub](https://clawdhub.com)
- [Skills docs](https://docs.molt.bot/tools/skills)
- [Sub-agents docs](https://docs.molt.bot/tools/subagents)
- [Cron jobs](https://docs.molt.bot/automation/cron-jobs) (if proactive needed later)

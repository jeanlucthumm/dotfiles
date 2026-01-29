# Moltbot Setup

## What is Moltbot

[Moltbot](https://github.com/moltbot/moltbot) is a local-first personal AI assistant that integrates with messaging platforms (Telegram, WhatsApp, Signal, etc.). Key features:

- Runs on your own devices via WebSocket gateway
- Multi-channel messaging integration
- Cron jobs, webhooks, file operations
- Tool/skill plugins via ClawdHub
- Recommends Anthropic Pro/Max + Opus 4.5

Install: `npm install -g moltbot@latest && moltbot onboard --install-daemon`

## Use Case 1: Chore Automation Queue

**Goal**: Telegram-based task queue where I can add chores, and the bot manages context and can reach out for clarification.

### Features Needed

- [ ] Chore folders with markdown context files
- [ ] Queue system - add tasks via Telegram messages
- [ ] Bot stores context per chore (details, history, blockers)
- [ ] Bot can proactively ask for more info when needed
- [ ] Persistent storage of chore state

## Use Case 2: Daily Check-in / Auto-Journal

**Goal**: Chat that tracks my day, keeps me on task, and generates daily summaries.

### Features Needed

- [ ] Auto-timestamp messages in the chat log
- [ ] Aware of current todos
- [ ] Aware of calendar for the day
- [ ] Regular check-ins - bot prompts to see if on track
- [ ] Reorganization suggestions when falling behind
- [ ] Auto-journal: conversation serves as activity log
- [ ] Daily summary generated and stored at end of day

## Resources

- [Moltbot GitHub](https://github.com/moltbot/moltbot)

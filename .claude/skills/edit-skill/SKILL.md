---
name: edit-skill
description: Open a skill's SKILL.md in Neovide for Jean-Luc to hand edit or review, then pick up his changes when he closes the window. Trigger on "let me hand edit that skill", "open the skill in neovide/nvim", "/edit-skill <name>". NOT for authoring skills from scratch (skill-writing) or code review (review-nvim).
---

# edit-skill

Pop the target skill's SKILL.md in Neovide, let Jean-Luc edit by hand, and pick
up his changes when he closes the window.

## Steps

1. **Resolve the target.** Name from args, else the skill under discussion.
   Look in `~/.claude/skills/<name>/SKILL.md`, then the project's
   `.claude/skills/`, `.agents/skills/`, and commands
   (`~/.claude/commands/<name>.md`, project `.claude/commands/`). Ambiguous or
   missing: ask instead of guessing.

2. **Read the file first** so you can diff after he closes.

3. **Launch in background Bash** (never blocking the conversation):

   ```
   neovide --no-fork <path>
   ```

   `--no-fork` matters: Neovide detaches by default, so without it the task
   completes immediately instead of when the window closes.

4. Tell the user the window is up (one line), then keep working or chatting.

5. **When the task completes**, re-read the file and diff against your
   snapshot. Summarize what he changed. If the edits correct something you
   wrote, that is feedback on skill style — worth remembering. If he wants
   other files from the skill (references/, assets/), same pattern.

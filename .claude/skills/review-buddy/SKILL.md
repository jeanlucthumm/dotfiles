---
name: review-buddy
description: Jean-Luc's recurring review-QUEUE triage ritual. Trigger ONLY when he names it ("review buddy", "/review-buddy") or asks to go through his review queue as a whole. NOT for reviewing a specific PR, diff, or branch.
---

- State (parked/ignored PRs and why) lives in `~/memory/github-review-state.md`; read it first.
- PRs that already have an approval from another reviewer default to skip.
- After finishing the queue, do a removal pass on the state file, not just additions: drop entries for PRs that merged or left the queue.

---
name: comms-spawn
description: Instructions on how to spawn new background agents. These are _sibling_ agents, not the same as subagents (which should be used instead in 90% of use cases).
---

To spawn sibling agents use `claude --bg -n <name> "<prompt>"`

These will show up in the user's `claude agents` overview, and
you'll also be able to message them as a peer.

Do not default to this mode. Subagents should still be preferred
unless there's a clear reason.

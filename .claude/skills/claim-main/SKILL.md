---
name: claim-main
description: Instructions on how to claim the main worktree for local testing etc.
---

Main worktree is atomic because we can only run one instance of the local stack.

Any jj checkout command or alike will automatically try to claim the worktree,
you don't have to do it manually.

If curious, status can be reported via `.git/claude/hooks/main-lock.py status`
(in the main worktree folder)

Release the claim as soon as you're done with main (tests finished, stack no
longer needed): `python3 .git/claude/hooks/main-lock.py release`. Holding it
blocks every other session's mutating ops on main; the 30-min stale-steal is a
safety net, not the release mechanism.

To wait for the local stack to come up, use `.git/claude/wait-for-stack.sh` in a loop/monitor

```
wait-for-stack, block until dev-stack services are ready, or fail with a diagnosis.

Usage:
  wait-for-stack.sh                          # wait for web-server + chatgpt-mcp
  wait-for-stack.sh web-server web-renderer  # wait for specific services
  wait-for-stack.sh --timeout 300            # override the 900s default

Designed for agents: launch it as a background Bash command and proceed when
it exits. Silent while waiting; exits 0 with a one-line "ready after Ns", or
exits 1 with a short diagnosis (Skipped service, crashloop, timeout, stack
down). Strictly read-only: never starts, stops, or restarts anything.

Ready = process-compose reports the process healthy AND its HTTP readiness
endpoint answers (process state alone is not enough: web-server's readiness
is only a log line, and in headless mode page URLs 502 forever because
web-renderer is Skipped, the motivating failure for this script).
```

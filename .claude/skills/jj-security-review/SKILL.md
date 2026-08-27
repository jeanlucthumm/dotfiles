---
name: jj-security-review
description: Security review of the pending changes on the current branch in a jj repo. Use when the user asks for a security review (/security-review, /jj-security-review) and the session is in a jj workspace or colocated jj checkout — the built-in /security-review shells out to git, which is blocked in Claude Code jj workspaces (no .git, GIT_CEILING_DIRECTORIES).
---

# Security review (jj edition)

Same job as the built-in `/security-review`, but the diff comes from jj.
The built-in fails in `.claude/worktrees/` workspaces because its context
preamble runs `git log`, and those workspaces deliberately have no `.git`.

Alternative when you want the genuine built-in: run it from the colocated
main checkout — `jj new <branch-bookmark>` there (git HEAD follows to the
branch head), then `claude -p "/security-review"` headless from that
directory, then restore main's `@` and abandon the parking commit. Respect
the main-checkout lock if the repo has one.

## Gather the changes

The review target is everything the current branch adds over trunk,
including uncommitted working-copy edits:

```bash
BASE=$(jj log --no-graph -r 'latest(::@ & ::trunk())' -T 'commit_id')
[ -n "$BASE" ] || { echo "no merge base with trunk()"; exit 1; }
jj log --no-graph -r "$BASE..@" -T 'commit_id.short() ++ " " ++ description.first_line() ++ "\n"'
jj diff --from "$BASE" --to @ --stat
jj diff --from "$BASE" --to @ --git
```

`latest(::@ & ::trunk())` is the merge base, which stays correct after
trunk moves ahead of the branch; `trunk()` alone is NOT an ancestor of
`@` then, and naive bookmark revsets come back empty (guard on empty
BASE — an empty `--from` makes jj diff against the root and the "diff"
becomes the whole repo). For large diffs, take the stat first and read
hunks file-by-file rather than dumping everything.

## Review posture

You are hunting for vulnerabilities the diff INTRODUCES or enables, not
auditing the whole repo and not doing general code review. Quality,
style, and performance are out of scope; a finding must be a security
consequence.

Look for the high-signal classes: injection of any kind (SQL, command,
path, template, header), authz gaps (missing ownership/permission checks,
IDOR, confused-deputy paths, mass assignment), authn weaknesses, secrets
or tokens in code/logs/error bodies, SSRF and open redirects, unsafe
deserialization or dynamic code execution, XSS/CSRF on rendered
surfaces, crypto misuse, race conditions with security consequences
(TOCTOU, double-spend), resource-exhaustion primitives reachable by
untrusted input, and privacy/compliance regressions (consent bypass, PII
into logs or third parties).

For each candidate finding, read enough surrounding code to decide
whether an attacker can actually reach it with input they control.
Trace the data flow; do not report on pattern-match alone. The bar for
reporting: you could defend the finding to the diff's author with a
concrete attack scenario. When something looks wrong but you cannot
construct the scenario, say so explicitly in one line at the end rather
than inflating it into a finding. Test-only files and fixtures are out
of scope unless they weaken production behavior.

## Report

Report findings with the ReportFindings tool, most severe first, each
with file, line, a one-sentence summary, and the concrete
failure/attack scenario (empty findings array if nothing survived
verification). Then give the user a short prose verdict: what was
reviewed (base..head, files), what you looked hardest at, and any
near-findings you chose not to report and why.

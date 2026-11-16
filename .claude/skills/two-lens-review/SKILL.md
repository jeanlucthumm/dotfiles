---
name: two-lens-review
description: Cheap autonomous review of a PR or pending change. The default before marking a PR ready.
---

Deliberately thin: two lenses, verify before reporting, one fixup round.

## Shape

Spawn two subagents in parallel (general-purpose, fresh context). Never
review your own diff in your own context — you wrote it, you will defend it.
The subagents get the PR URL (or, for unpushed work, the workspace path and
`jj diff -r <change>` instructions), the change's stated intent, and nothing
of your reasoning. They read code directly in a workspace with the change
checked out: yours if you wrote it, otherwise find one with `jj workspace list`. If you authored the diff, write the reviewer prompts
neutrally: don't steer them toward or away from anything — no "I already
checked X", no hints about which parts you're confident in.

Common spine, in both prompts:

- You are READ-ONLY. Never edit files, never run mutating commands (no jj/git
  writes, no gh mutations, no installs). You report findings up; the author
  applies fixes. In a jj workspace any stray edit auto-snapshots into the PR
  commit, so this is a hard rule, not a preference.
- You did not write this change; try to break it.
- Fetch the diff (`gh pr diff <n>`, or jj for pending work) and read enough
  surrounding code at the branch to VERIFY each candidate before reporting.
  Unverified hunches stay out or go in marked unconfirmed.
- An empty findings list is a valid, good outcome.
- Never comment on the PR; return findings only.
- Not findings: anything a linter or typecheck catches, pre-existing
  issues on untouched lines, restating the PR description.
- Return structured findings — `{file, line, summary, lens,
  severity: major|minor, confirmed: bool}` — plus a one-line verdict on the
  PR overall.

Functionality lens, in order:

- (a) line-by-line scan of the diff for bugs;
- (b) removed or changed behavior something else may depend on;
- (c) cross-file tracing of every symbol the diff touches;
- (d) purpose — given the change's stated intent, would it actually survive
  the scenario that motivated it?

`confirmed=true` only when the agent can state the concrete inputs/state
that produce wrong behavior.

Quality lens, in order:

- (a) reuse — does the diff duplicate a helper, fixture, or pattern that
  already exists nearby (go look);
- (b) simplification — is there a plainly simpler shape for the same
  behavior;
- (c) efficiency — wasted work only if it plausibly matters in this context;
- (d) altitude — is the change at the right layer/place, per the surrounding
  code's conventions and any CLAUDE.md/AGENTS.md rules scoped to these paths;
- (e) necessity — every piece of the diff should earn its place. Flag anything
  a reviewer would ask "why is this here?" about: dead or unreachable code, a
  second home for something defined elsewhere, a comment that restates the code.

These are judgment inputs: `confirmed=true` only when the better alternative
concretely exists (the agent found the helper, or can sketch the simpler
shape).

## Fixup round

Exactly one: fix confirmed-major findings; confirmed-minor at your judgment
(fix if cheap, otherwise carry them into the report); unconfirmed findings
are reported, not acted on. A behavioral fix ships with a test that sets
up the finding's inputs/state and fails without the fix. Re-run static
checks after fixes. Do not loop —
a second full review pass is the human's call, not yours.

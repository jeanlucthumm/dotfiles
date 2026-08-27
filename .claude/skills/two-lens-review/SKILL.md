---
name: two-lens-review
description: Autonomous two-subagent code review of a PR or pending change — one fresh-context functionality lens (bugs, removed behavior, cross-file tracing, purpose), one code-quality lens (reuse, simplification, efficiency, altitude) — verified findings only, then one fixup round. Use before marking a PR ready, or whenever an autonomous review is wanted and the human-only /code-review can't be fired. Flag meaty diffs for Jean-Luc to run the real /code-review himself.
---

# Two-lens review

Why this exists: the bundled /code-review is human-invocation-only, and its
autonomously reachable form (headless `claude -p`) is a single inline pass —
no richer than a pass we control, but opaque and unparseable. This is the
controlled version, extracted from the web-ci-mass-pass workflow's review
stages. It is deliberately thin: two lenses, verify-before-report, one fixup
round. It is NOT a substitute for the full multi-angle harness; when a diff
deserves that, say so (see Escalation).

## Shape

Spawn two subagents in parallel (general-purpose, fresh context). Never
review your own diff in your own context — you wrote it, you will defend it.
The subagents get the PR URL (or, for unpushed work, the workspace path and
`jj diff -r <change>` instructions), the change's stated intent, and nothing
of your reasoning. If you authored the diff, write the reviewer prompts
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
- Not findings: style nits, anything a linter or typecheck catches,
  pre-existing issues on untouched lines, restating the PR description.
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
  code's conventions and any CLAUDE.md/AGENTS.md rules scoped to these paths.

These are judgment inputs: `confirmed=true` only when the better alternative
concretely exists (the agent found the helper, or can sketch the simpler
shape).

## Fixup round

Exactly one: fix confirmed-major findings; confirmed-minor at your judgment
(fix if cheap, otherwise carry them into the report); unconfirmed findings
are reported, not acted on. Re-run static checks after fixes. Do not loop —
a second full review pass is the human's call, not yours.

## Escalation

When the diff is meaty — wide blast radius, subtle semantics, wire/protocol
changes, framework rewrites — name it in your report as a candidate for
Jean-Luc's full-harness /code-review. His reviews run async: never block
dependent work on them. Stack the next change on top and fold his findings
into the PR commit when they arrive (jj auto-rebases descendants).

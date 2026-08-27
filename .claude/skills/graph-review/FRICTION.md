# Friction log

Observations from live runs that should shape the next revision of this
skill. Admission bar: process pain seen in a real graph run, one bullet
each, dated.

- 2026-08-16 (MCP v2 endgame drain): the single long-lived stack fixer
  agent hit ~500k context by the end of the drain. JL: not acceptable.
  One accreting fixer per graph does not scale; rethink iteration for
  graphs. Candidate direction: fresh agent per dispatch, with continuity
  carried by a state doc (bookmark map, standing rules, per-PR notes)
  instead of the agent's own transcript.
- 2026-08-16 (same run): CI watcher treated "zero pending checks" as
  GREEN, but the required contexts had simply never started on the new
  push (only Wiz scanners ran); armed auto-merge sat outside the queue
  for an hour. Watchers must assert the required contexts EXIST (by
  name) before calling green, not just that none are pending/failing.
- 2026-08-16 (same incident): the missing contexts were caused by a
  THIRD silent state the drain procedure did not model: a sibling's
  merge made the PR CONFLICTING, GitHub stops building the merge ref,
  and merge-ref-based CI (Semaphore) never starts. Diagnosis path that
  worked: other PRs have contexts + this head has zero -> check
  mergeable. After any sibling merges, check mergeable on the survivors
  before trusting their CI state.
- 2026-08-17 (post-drain SEV1, Rootly 3298): the drain's D2 gate
  ("prod runs the endpoint deletion before the allowlist drop")
  sequenced two halves of the WRONG invariant. The real dependency was
  on a released client's hardcoded resource indicator, which no
  traffic metric can prove unused (the endpoint had a week of measured
  zero authenticated traffic and deleting it still took down every
  login). Lesson for deletion-shaped nodes: the gate question is not
  "is the server side quiesced" but "has every released client stopped
  sending the identifier", and only client-side release evidence
  answers it.

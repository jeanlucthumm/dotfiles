---
name: graph-create
description: Turn a scoped project into a PR-sized implementation graph (a plan doc that /graph-execute can run). Trigger: "implementation graph", "plan the PR graph", or when a project is about to move from research to multi-PR execution. Not for single-PR work or for research that has no execution phase behind it.
---

The output is a plan doc that /graph-execute can run without you in the
room. Everything below serves that: a coordinator session will read this
doc cold (possibly post-compaction) and launch each node as a
self-contained background job.

## Adversarial verification, not more research

The authoring session usually has all the context it needs; what it
cannot do is distrust itself. You wrote the plan, you will defend it.
So after drafting, send out an adversarial agent with a deliberately
unbiased prompt: the doc path and "verify this independently against
primary sources; try to break its premises, edges, and node scoping".
No author reasoning, no hints about which parts you're confident in.
A wrong premise costs far more mid-execution than one verification pass
costs now; in this skill's first run it reshaped the entire rollout.

Don't trust a single pass's negative risk judgments ("unlikely to
collide", "nothing applies here"). For domains feeding risk-carrier
nodes, run a second independent pass: same questions, fresh agent,
blind to the first round's findings. The passes run sequentially,
never in parallel: triage round one and fold any redraft into the doc
before the second agent launches, so it verifies the doc as it now
stands instead of a version already known to be wrong. Blind means
the second agent never hears what the first one found — not that the
two run at the same time.

Decisions that belong to the user (rollout shape, testing strategy,
review model) get elicited explicitly, batched via AskUserQuestion, not
buried in prose. An unanswered elicitation is not a settled decision.

## The output

One test decides whether the doc is done: a cold coordinator (fresh
session, post-compaction) could turn every node into a self-contained
launch prompt without asking anyone anything. That makes these things
load-bearing:

- Nodes that are each one PR, respecting the repo's PR-splitting rules.
- Dependency edges (launch order falls out of them).
- A gate per node: deterministic where cheap to encode (status codes,
  transcript diffs); otherwise an LLM reads the transcript and judges.
  Don't build assertion machinery a reading settles.
- Human gates named: which nodes are risk carriers getting the full
  /code-review, and that reviews gate merges, never development.
- A rollout paragraph, plan-level not per-node: the critical path of what
  goes live when, which nodes actually change live behavior, and where the
  revert points are (dark by construction, flag-gated, redeploy). This
  decides up front whether flag machinery is a node of its own.
- A Run state section, initially empty: the executor owns it (node
  status, PR numbers, agent IDs, accumulated traps).

Everything else (sizes, critical-path drawings, doc headers) is taste;
add what helps, enforce nothing.

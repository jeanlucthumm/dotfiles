---
name: graph-review
description: Coordinate review of a multi-PR graph or stack until every PR is stamped. Not for reviewing a single PR (pr-walkthrough), running one PR's review-response loop (pr-iteration), or merging.
---

Coordinator role for getting every PR in a graph reviewed and stamped.
Compose, don't absorb: pr-walkthrough is the per-PR card mechanic,
pr-iteration the arbiter loop. This skill is the discipline around them.

Card 0 is always the graph overview: nodes with status, the decision
list mapped to cards, rollout shape.

## Run state

One doc on disk is the source of truth (triage, stamps, dispositions); the
conversation is disposable. Write a carry-over message before each
compaction. Log entries are one clause per event; detail GitHub already
records is token waste.

## Triage

Split card-worthy vs stampable up front, not mid-run. A node commissioned
on an explicit decision record (spec basis, gates, rationale) gets stamped
on that record; deep cards are only for risk carriers and judgment calls.
When scope moves between nodes, re-derive gates from scratch; a stamp must
not inherit gates from work that left the node.

## Coordinator discipline

- Bulk log/trace reading goes in a subagent.
- Converge open design questions in chat, write the record, then dispatch a
  builder once. Ping-ponging corrections through an agent triples the cost.
  This covers design SHAPE inside a commissioned fix too: when a fix has
  more than one reasonable shape, name the shapes in chat before the brief —
  a taste-level choice embedded silently costs an agent round when the user
  reworks it.
- No ambient CI/review sweeps; the review phase ends at stamps.
- One long-lived fixer agent per graph region, revived by agentId, so
  context carries across nodes — but with a context budget. Task
  notifications report subagent_tokens; past ~350k, retire the agent
  (fresh investigator for questions, fresh implementer seeded with a
  distilled brief) instead of another revival. A revived agent still
  displays the name it was spawned with; when mentioning it, say what it
  is working on now.
- Never message a parent job that has live background children (it orphans
  their completion reports).
- Node codes mean nothing to the reader by themselves; every mention
  carries its meaning inline, like "B2 (dual-era serving)". Comment labels
  get their own namespace, never node names.

## Evidence

Card claims come from the diff, not the node's plan entry — but the
coordinator still never reads diffs. The pattern that squares this: one
builder subagent per PR reads the diff, writes the deck, and returns a
per-card fact sheet (claims with file:line anchors, verified vs inferred)
that the coordinator narrates from. Brief builders with "diff wins, report
discrepancies": they audit the plan doc for free (stale comments, wrong
metric names, overstated scope), and the plan entry gets corrected. Before
contradicting the user's factual claim, check the primary source (ticket,
dashboard, code), not memory docs.

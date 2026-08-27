---
name: graph-execute
description: Coordinate execution of a PR-sized implementation graph (plan doc from /graph-create). Trigger: "start the graph", "continue the graph", or resuming graph coordination after compaction. The session becomes a coordinator that launches node jobs; not for single-PR work, and not a Workflow (workflow agents cannot spawn the reviewer subagents nodes need).
---

Input: a plan doc satisfying the /graph-create contract. The doc is the
run's living state: update node status, PR numbers, decisions, and the
accumulating trap list there as things land. You (the coordinator)
survive compaction only through it. Keep run-state entries one line
each. Review/CI bookkeeping (arbiter findings, fix routing, check
status) never enters the doc — handle it silently in the background;
only durable outcomes do: a verified premise correction, a decision,
a new node or PR. Edit its run-state region by
Read-then-Edit; reciting old_string from memory fails repeatedly and
costs more than the read.

## Coordinator with judgment

One node = one background job (Agent tool, general-purpose, worktree
isolation) launched as the graph unblocks. This is deliberately not a
deterministic pipeline: nearly every inter-node moment needs a call a
script can't make (a finding reshapes downstream work, a gate exposes a
stale premise, a companion PR needs spawning). You make those calls
between launches; jobs make none of them.

Record each node's agent ID in the plan doc at launch. A stopped or
vanished agent revives via SendMessage to that ID (its transcript
persists); prefer reviving the owner over spawning a finisher.

Stay at the coordination altitude: never read diffs in your own context;
PR descriptions, CI state, and job reports only. Anything needing diff
inspection goes to a subagent that returns conclusions.

## Launch prompts are the only reliable channel

Everything a job needs goes in its launch prompt: docs to read, the
node's spec, gates, repo mechanics, the trap list accumulated from prior
nodes' reports, and the report shape you want back. Each report feeds
the next prompt; the trap list lives in the plan doc, not here.

Never message a running job that has live subagents of its own.
Resuming a parked parent strands its children's completion reports at
the session root, and you become a mailman for orphaned reports
(verified the hard way). Poke only a job that is genuinely wedged, and
expect to relay its children's reports afterward.

A design revision that lands while a node is mid-flight goes to the
OWNER, finish-then-relay: let the running agent complete its launched
spec, then send the delta via SendMessage after its report. Its
transcript makes the rework cheap; a fresh agent re-buys all the
context.

## jj is the substrate

1 PR = 1 commit, amended forever; bookmarks force-pushed. The payoff is
stacked fold-in: when review findings amend a mid-stack commit, jj
auto-rebases every descendant, and the cost is bounded conflict waves.
Route each conflicted commit to the job that owns it; a job never
resolves conflicts in a parent's commit. Budget one wave per risk
carrier amend and don't fear them; they run without the human.

## Two review tiers

Every node runs the two-lens-review skill (two read-only reviewer
subagents, verified findings, one fixup round) before drafting its PR.
It is often missing from a job's in-context skill list; launch prompts
say it exists in the skills folder so jobs don't conclude otherwise.
Launch prompts also point PR bodies at the pr-description skill.
Risk carriers, named in the plan, additionally get the full /code-review
harness, which only the user can fire: review-only, never --fix, one
writer per change. Its findings JSON is compact; it flows through you,
and you route fixes to the job owning that change's workspace.

Reviews gate merges, never development: stack the next node immediately,
and accept that a structural finding on a parent reworks stacked work.

PR watching stays with the coordinator; dispatched jobs never watch. But
a dispatched fixer pushes and replies to threads under the user's own
token, so an armed watcher reads its work as human activity. After
routing a fix, hold the re-arm until the owner's report lands.

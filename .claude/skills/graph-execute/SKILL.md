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

Record each node's agent ID in the plan doc at launch. A job that
vanishes mid-spec revives via SendMessage to that ID. After a job
reports, the node's follow-ups (review fixes, rework, conflicts) go to
its fixer: one fresh agent per node, spawned at the first follow-up and
reached by SendMessage after that. Owners finish near their context
ceiling and degrade when revived.

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

A design revision that lands while a node is mid-flight waits for the
job's report, then goes to the node's fixer as a delta.

## jj is the substrate

1 PR = 1 commit, amended forever; bookmarks force-pushed. The payoff is
stacked fold-in: when review findings amend a mid-stack commit, jj
auto-rebases every descendant, and the cost is bounded conflict waves.
Route each conflicted commit to its node's fixer; nobody resolves
conflicts in a parent's commit. Budget one wave per risk
carrier amend and don't fear them; they run without the human.

## GitHub stacks

Link each chain from the plan's Stacks section once its PRs exist:
`gh stack link <bottom-pr> ... <top-pr>`, by PR number.
Land with `gh stack merge <pr>`: atomic, everything below included;
stacked PRs have no auto-merge. A fan-in node lands only after both
parents have, through their own stacks. After any landing, fetch and
restack the rest in jj — never the UI "Rebase stack" button. Never
reorder pushed layers: GitHub marks a PR merged, irreversibly, once its
head is reachable from its base. Insertion is top-only; otherwise
unstack and relink.

## Two review tiers

Every node runs the two-lens-review skill (two read-only reviewer
subagents, verified findings, one fixup round) before drafting its PR.
It is often missing from a job's in-context skill list; launch prompts
say it exists in the skills folder so jobs don't conclude otherwise.
The job acts on two-lens findings itself; they never come to you.
Launch prompts also point PR bodies at the pr-description skill.
Risk carriers, named in the plan, also get /code-review, fired by the job
on its own PR after two-lens (Skill tool, review-only). The job never
acts on its findings alone; it reports them to you. You triage each
against the design doc and the rest of the graph (/code-review sees
neither) and decide which to fix and which to rebut. The job ends at its
report; the triaged list goes to the node's fixer, so no agent waits on
you. Waits on outside events (Arbiter, CI) are what strand parked jobs. Every review fix ships
with a test that reproduces the finding's failure scenario: a fix built
on a misreading of the finding still passes tests that never set up that
scenario.

Reviews gate merges, never development: stack the next node immediately,
and accept that a structural finding on a parent reworks stacked work.

When a micromanager approve stands in for a domain review, the ask
carries a ready reason the approver can say yes to. The reason argues why
skipping that review is safe (blast radius, review evidence,
reversibility), never what the PR does: the PR already says that. It's
public, so review evidence goes in plain words, not private skill or node
names. This one keeps slipping, so check every reason before it goes out.

PR watching stays with the coordinator; dispatched jobs never watch. Keep
a `Watch:` line of open PRs in the plan doc and arm pr-iteration's watcher
with `--prs-from` on it. Add `--required-only` when non-required checks fail
for reasons outside the graph (flaky on main); a real break in one then goes
unseen.

## Friction Notes

- The coordinator rewrites the plan doc's Run state often, so a separate planner session's edits
  to the same doc keep bouncing. The planner sends rulings by message, and the coordinator folds
  them into the doc and confirms.

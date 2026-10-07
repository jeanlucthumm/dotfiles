# Skill eval process: notes from the dreaming experiments

Status: loose write-up. Descriptive, not prescriptive. n=2 runs as of this date;
revisit each time a run lands, promote or demote items between buckets. Do not
turn into a skill until many more runs exist.
Date: 2026-10-07

## Why loose

The point of writing this down early is to not lose the observations, and the
point of writing it loosely is that run-001's headline lesson ("terse prompts
are safer, rails are churn") was inverted by run-002. Prescribing after two runs
would have frozen the wrong conclusion. Treat this as a lab notebook summary
with confidence labels, not a method.

Context: the skill under test is a memory "dream", a consolidation pass over a
markdown memory directory (dedupe, fix contradictions at the source, archive
stale content, refresh indexes). Everything below came from building and
testing that one skill. Corpus, prompts, patches, judge outputs and the per-run
notebook live in the private repo `jeanlucthumm/llm-dreaming-research`
(`~/llm-dreaming-research`, see `experiments/experiments.md`).

## The loop as it actually ran

1. Research fan-out: parallel agents plus a recursive scoping workflow built an
   evidence corpus (27 findings files, ~110 downloaded artifacts). From that,
   a first "golden" prompt was synthesized.
2. Freeze a fixture: snapshot a real memory subdir into a versioned repo,
   plant a few canary facts, commit as base. Fork one copy per variant. The
   live memory is never touched.
3. Run each variant as a fresh-context subagent inside its own copy, blind to
   the others.
4. Deterministic floor: canary survival, diffstat, and (from run-002) a
   coverage count against a ground-truth list built by a separate read-only
   audit agent.
5. Blind pairwise judges on anonymized diffs, both presentation orders,
   rubric-scored on five axes, verifying claims against the base snapshot.
6. Notebook entry: verdict, "guidance extracted", "harness changes".
7. Fold the guidance (and the loser's unique catches) into the next golden,
   run again against the incumbent.

## Bucket 1: survived both runs, would bet on these

- Pairwise over solo review. A single output always "looks reasonable". Only
  the pair plus a verdict produced signal.
- Fresh-context executors. The agent that wrote the memory must not be the one
  reviewing it; it rationalizes its own work.
- Frozen fixture, diff as the unit of review, copies instead of the live
  target. Made every run safe and every comparison fair.
- Aggregate rubric totals, ignore verdict sentences. In run-001 a judge scored
  one variant higher and then declared the other the winner.
- Both presentation orders, always. In run-001 both judges preferred whichever
  patch they saw second. In run-002 the gap was large enough that the bias
  vanished, but we only know that because both orders ran.
- Same-prompt variance baseline before trusting a delta. Running the champion
  twice in run-002 gave a noise band (61 vs 64 on judges, 1 vs 3 on coverage)
  that made the challenger's margin legible.
- A dedicated ground-truth audit beats judge impressions for completeness. The
  "10 of 44 index lines are stale, here is the evidence" list turned coverage
  into a number and was the single most useful harness addition.
- Losses teach rails. Every error of commission mapped to one missing
  instruction, and the fix was one line in the next prompt.

## Bucket 2: flipped once already, hold loosely

- "Terse is safer." Run-001: the 11-line prompt won with zero errors; the
  rail-heavy prompt made the only factual error. Run-002: the rail-heavy prompt
  (with a new freshness rail) won 175/200 to 61 and 64 out of 100, and both
  terse samples made the factual errors. Density was never the variable that
  mattered; one specific rail was.
- Where commission errors come from. Run-001: the broad variant. Run-002: the
  narrow variants. Common root in both: writing a summary line without reading
  the source to its latest dated entry. Tentative generalization: errors
  cluster in newly written lines, not in edited ones.
- Judge taste on style. One run-001 judge praised symlink-aware link renames;
  three of four run-002 judges called the same behavior churn. Style axes are
  noisier than factual axes.
- Canary methodology. Appended, undated canaries were detected as "planted" by
  the stronger prompt and quarantined. That measures hygiene, not accidental
  information loss, which is what canaries were for. Next: embed them inside
  dated entries mid-file.

## Bucket 3: open questions, what more runs are for

- Does any of this transfer beyond skills whose output is a diffable file tree?
  Side-effecting skills (Slack, PRs) would need dry-run or mocked targets.
- How few judges are enough? Two split; four were unanimous. The minimum is
  unknown and probably depends on the size of the real gap.
- Does the ground-truth audit generalize when truth is not derivable from the
  fixture itself? Memory consolidation is unusually self-consistent.
- Cost. A run was roughly a million tokens. Which skills are worth that, and
  is there a cheap-tier version for the rest?
- One fixture family so far (the MCP memory dir). Risk of overfitting to its
  conventions. Rotating fixtures across projects is untested.
- Champion/challenger with several folded changes (run-002) vs one variable per
  pair (run-001). Faster vs cleaner attribution. No evidence yet on which to
  prefer.
- How many runs before prescribing anything. This document's own question.

## Numbers for reference

- run-001 (2026-08-27): terse 80/100 vs golden v0 72/100 on summed rubrics;
  golden made one real commission error; two judges split, both favoring the
  second-presented patch.
- run-002 (2026-09-10): golden v1 175/200 vs terse 61 and 64 /100; coverage
  10/10 vs 2/10 and 3/10 stale index lines fixed; four of four judges
  "decisive" for golden in both orders.

# Prior art: LLM-generated PR review guides / narrated code review

Research report from a web sweep on 2026-08-12. One correction applied after
reading source: guidedreview's prompt DOES enforce hunk-level coverage (hunk
inventory + "every id must appear in exactly one unit"), so the "nobody does
hunk-level coverage" gap below is narrower than first reported. Our
differentiator is code-side partition validation plus coverage made visible
in the UI.

## Per-tool findings

### 1. Graphite (Diamond / Graphite Agent) — NOT a review-guide product

Correction to the premise: Graphite has no named "review guide" or
narrated-walkthrough feature. Diamond (since renamed and folded into
"Graphite Agent") is an inline AI *reviewer*: it posts bug/logic/security
comments on hunks, plus AI PR summaries. It does not chunk the diff into a
narrative. What IS transferable from Graphite:

- **Context strategy**: hybrid "diff + relevant slices" — always the diff
  plus a ranked list of nearby code (imports, callers, test files), with
  context "deduplicated, compressed, ranked, and filtered before it reaches
  the model" ([Graphite guide on context](https://graphite.com/guides/ai-code-review-context-full-repo-vs-diff)).
- **Eval strategy** (Braintrust case study): quality measured by behavioral
  signals — acceptance rate (developer commits the suggested change),
  upvote/downvote rate — plus custom scorers including **line-range
  validation** (does the comment anchor to real diff lines) and
  semantic-similarity consistency checks
  ([braintrust.dev/blog/graphite](https://www.braintrust.dev/blog/graphite)).
- Links: [graphite.com/features/ai-reviews](https://graphite.com/features/ai-reviews),
  [Series B / Diamond launch](https://graphite.com/blog/series-b-diamond-launch),
  [Graphite Agent rename](https://graphite.com/blog/introducing-graphite-agent-and-pricing).

### 2. Linear Diffs "Guide" tab — the closest match to this design

Linear's guided reviews (beta, shipped with Linear Diffs ~May 2026) are
almost exactly guide.json rendered as a product:

- "Guides surface the core parts of an implementation first while grouping
  supporting or lower-signal changes separately." Core-change-first ordering,
  explicit **glue-code/secondary-change separation** so the reviewer isn't
  forced through boilerplate.
- "Each section pairs a high-level explanation of *why* a part of the change
  exists alongside the relevant diffs": intent paragraph first, then the
  code. Explanations start "with what the change is, then moving into its
  consequences."
- Sections carry **direct links into the relevant parts of the PR** so you
  can move between guide and raw diff. That bidirectional anchoring is their
  answer to the trust problem.
- A user quote captures the goal: "Linear groups the change into chunks that
  read like a story, so I can follow the logic instead of skimming a wall of
  red and green."
- Generation mechanism is not public. Auto-generated per PR; toggle in
  GitHub integration settings; Business/Enterprise only.
- Links: [linear.app/docs/diffs](https://linear.app/docs/diffs),
  [linear.app/diffs](https://linear.app/diffs),
  [changelog](https://linear.app/changelog/2026-05-27-linear-diffs),
  [Reviewing code in the agent era](https://linear.app/now/reviewing-code-in-the-agent-era).

### 3. CodeRabbit — the most public mechanism ("cohorts")

CodeRabbit publishes the most detail of anyone:

- **Walkthrough comment** (docs): high-level summary, a **changed-files
  table that groups related files into consolidated rows** (e.g. 1 source
  file + 27 locale files = 2 rows), Mermaid **sequence diagrams** for
  interaction changes, a 1-5 **estimated review effort** score, related
  issues/PRs, linked-issue assessment. Every section individually
  toggleable. [docs.coderabbit.ai/pr-reviews/walkthroughs](https://docs.coderabbit.ai/pr-reviews/walkthroughs)
- **Cohorts** (blog): "it identifies semantic relationships between changes,
  groups related code blocks into logical cohorts, and orders those cohorts
  by dependency." Ordering example is literally narrative order: "starting
  with the schema, then the business logic that depends on it, then the call
  sites that invoke that logic, then the front end, then unit tests, and
  finally integration tests."
- Built on a cloned repo + "syntactic and semantic graph of the change", not
  diff-text-only.
- **Conservatism as anti-hallucination**: "Cohorts are grouped only when the
  relationships are clear, and diagrams appear only when they make those
  relationships easier to understand." They'd rather under-group than invent
  structure.
- Links: [Explainable AI Code Review blog](https://www.coderabbit.ai/blog/coderabbit-review-reads-a-pr-how-author-would-explain-it),
  [Change Stack / Atlas UI](https://www.coderabbit.ai/blog/introducing-atlas-the-first-ai-native-code-review-interface),
  [Overview page](https://www.coderabbit.ai/blog/introducing-overview).

### 4. Greptile

Not a narrator, an investigator, but its context model is instructive:
builds a language-agnostic call graph of the whole repo, then "follows the
diff outward through the graph — into callers, related files and git
history", with parallel agents chasing nested calls. Output: inline comments
+ PR summary + sequence diagrams, **each finding carrying a confidence
score** and supporting evidence from the codebase.
[greptile.com](https://www.greptile.com/), [docs intro](https://www.greptile.com/docs/introduction).

### 5. Sourcegraph Amp / Codegen / What The Diff

- **Amp** (ex-Sourcegraph): agentic review panel in VS Code, "pre-scans
  diffs and provides summaries, guidance, and actionable feedback", scoped
  to a task/commit-range/diff. Reviewer-agent, not a guide artifact.
  [tessl.io writeup](https://tessl.io/blog/amp-adds-agentic-code-review-to-its-coding-agent-toolkit/).
- **Codegen**: only generic code-review-agent marketing; no walkthrough
  feature found.
- **What The Diff**: PR-description generator from raw diff, plain-English
  summary, no chunking/ordering, avg PR ~2,300 tokens. Mostly evidence that
  flat summarization is the commodity baseline.
  [whatthediff.ai](https://whatthediff.ai/).

### 6. Academic prior art (well-studied under different names)

- **Changeset decomposition / untangling**: ClusterChanges (Barnett et al.,
  ICSE 2015, Microsoft) partitions a review changeset using **def-use and
  use-use relationships** ([paper PDF](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/barnett2015hdh.pdf));
  SmartCommit (FSE 2021) does graph partitioning over "hard links, soft
  links, refactoring links, and cosmetic links"
  ([PDF](https://www.cs.cmu.edu/~ckaestne/pdf/fse21_sc.pdf)); UTANGO
  (context-aware graph learning); and 2025-26 LLM-based untanglers
  ([TOSEM LLM untangling](https://dl.acm.org/doi/10.1145/3822177),
  [Atomizer multi-agent](https://arxiv.org/html/2601.01233)). The "story
  chunk" clustering is exactly this literature's problem; the durable signal
  is **static dependency links between hunks (def-use), not textual
  similarity**.
- **Ordering**: Baum et al. (2017) formalized optimal reading order as
  "tours" — related change parts adjacent — and showed grouping related
  parts matters most for reviewers with low working memory
  ([PDF](http://tobiasbaum.github.io/rp/memoryCodeOrderAndReview.pdf)).
  Fregnan et al. (2022) showed files lower in the review order get less
  attention and **more missed defects**: position bias is real, so what
  goes first matters. A 2023 study found alphabetical only weakly beats
  random and largest-diff-first beats alphabetical
  ([arxiv 2306.06956](https://arxiv.org/abs/2306.06956)). A 2025 survey of
  1,355 developers: only 10.2% think alphabetical is optimal; 66% want
  dependency-aware grouping ("Breaking the Alphabet",
  [Zenodo replication package](https://zenodo.org/records/17634647)).
- **Vision**: "Help Me to Understand this Commit!"
  ([arxiv 2402.09528](https://arxiv.org/html/2402.09528)) surveys 26
  code-reorganization studies and warns about reviewer cognitive load /
  analysis paralysis.
- **Hallucination in diff→NL specifically**:
  [arxiv 2508.08661](https://arxiv.org/html/2508.08661v1) measures
  hallucination prevalence in code-change-to-natural-language generation.
  Evidence that narration of diffs does hallucinate and needs anchoring.

## Open-source implementations to crib from

1. **guidedreview** (nshntarora, Chrome MV3 extension, BYOK) — the closest
   open implementation. Clusters PR diffs into "ordered review units" with
   explicit **"schema, then logic, then call-sites, then tests"** ordering,
   2-line summary per unit, maps units back to real diff lines ("line
   comments attach to the real diff lines shown for a unit, not to
   model-invented code"). Pipeline: read diff → send to provider → get
   review units + summaries → **map back to the diff** → render.
   Repo: https://github.com/nshntarora/guidedreview. Key source files are
   copied into `guidedreview/` in this folder.
2. **Qodo PR-Agent** (`/describe` tool) — mature open source, and its prompt
   file is directly readable:
   https://github.com/qodo-ai/pr-agent/blob/main/pr_agent/settings/pr_description_prompts.toml
   with driver
   https://github.com/qodo-ai/pr-agent/blob/main/pr_agent/tools/pr_description.py.
   Schema pattern worth stealing: Pydantic model rendered into the prompt,
   `pr_files: List[FileDescription]` where each file gets `filename`,
   `changes_summary` (1-4 bullets), `changes_title` (5-10 words), `label`
   (closed enum: 'bug fix', 'tests', 'enhancement', ...). Instructions
   include "Each file must be analyzed regardless of change size" (their
   coverage guarantee at file granularity) and "Order bullets by
   importance". They cap `pr_files` at 20 and have a large-PR compression
   strategy in `pr_description.py`. Prompt copied to
   `pr-agent-description-prompts.toml` in this folder.
3. **codedog** (https://github.com/codedog-ai/codedog) and **Gito**
   (https://github.com/Nayjest/Gito) — reviewer-style, less relevant, but
   codedog has per-file summarization prompt chains.

## Gaps confirmed (searched, found nothing)

- **No public Claude Code skill for review-guide generation exists.** All
  published skills (SpillwaveSolutions/pr-reviewer-skill,
  awesome-skills/code-review-skill, aidankinzett/claude-git-pr-skill,
  feiskyer's github-review-pr, etc.) are bug-finding/checklist reviewers;
  none clusters hunks into an ordered narrative. The gap is real.
- **Graphite has no review-guide/narration feature.** Its "guides" are
  educational blog content.
- **Neither Linear nor CodeRabbit publishes prompts, schemas, or a coverage
  algorithm.** The closest public statements are PR-Agent's file-level "each
  file must be analyzed" and guidedreview's hunk inventory + map-back step
  (see correction at top: guidedreview does prompt hunk-level coverage).
  The "narrative hides code" trust problem is essentially unaddressed in
  public writing; Linear's mitigation is UI (guide links into the raw diff,
  raw diff remains a tab), not a generation-time guarantee.
- No academic work found on LLM-chosen *reading order* specifically
  (ordering research predates LLMs and is heuristic/graph-based).

## Distilled design guidance for the guide.json generator

1. **Converged ordering exists, use it**: schema/data model → core logic →
   call sites → UI → unit tests → integration tests. Both CodeRabbit
   (dependency-ordered cohorts) and guidedreview state this order verbatim;
   Linear says "core of change first." Also front-load the most important
   chunk: reviewers' attention decays with position (Fregnan 2022).
2. **Make coverage a schema-level invariant, not a prompt instruction.**
   Enumerate hunks with stable IDs, require every chunk to reference hunk
   IDs from that list, then **validate the partition in code**: every ID
   assigned exactly once; unassigned IDs go into a forced trailing
   "everything else / mechanical changes" chunk rather than silently
   disappearing.
3. **Anchor, never quote.** Have the model return hunk IDs / file+line
   ranges and render the real diff text yourself (guidedreview: attach to
   "the real diff lines, not model-invented code"; Graphite's evals include
   a line-range-validation scorer). Never let the model reproduce code in
   the guide.
4. **Explicit low-signal bucket.** Linear's glue-code separation and
   CodeRabbit's consolidated rows (27 locale files = 1 row) both exist
   because lockfiles/codegen/renames drown narrative. Give the schema a
   `kind: "core" | "supporting" | "mechanical"` per chunk so the renderer
   can collapse mechanical ones, but they must still list their hunk IDs
   (coverage invariant).
5. **Granularity: be conservative and cheap.** CodeRabbit groups "only when
   the relationships are clear"; when unsure, smaller chunks with plain
   titles beat invented themes. A closed label enum per chunk (PR-Agent's
   'tests', 'error handling', 'config', ...) constrains the model more
   effectively than free-form theming.
6. **Paragraph structure: intent → consequence.** Linear's formula: what the
   change is, then its consequences; lead with *why the chunk exists* before
   what it touches. One paragraph per chunk is right. PR-Agent caps bullets
   (1-4) and title lengths (5-10 words); tight length caps in the schema
   measurably reduce rambling/hallucination.
7. **Clustering signal: dependency links beat topics.** The untangling
   literature (ClusterChanges def-use, SmartCommit link graph) says hunks
   belong together when one *uses* what the other *defines*. Even without
   static analysis, prompt the model to justify each grouping by a named
   symbol shared between hunks, and consider a cheap pre-pass (same file,
   shared identifiers via grep) fed in as candidate edges.
8. **Give the model more than the diff.** Every serious tool escalates
   beyond diff text: Graphite's "diff + ranked relevant slices" (imports,
   callers, tests), Greptile's graph walk. For a personal tool: include
   enclosing function/class context per hunk and the PR description; that
   alone closes most of the gap.
9. **Two-pass beats one-pass at scale.** For big PRs, PR-Agent
   compresses/summarizes per-file first, then composes; CodeRabbit
   dedupes/ranks/filters context before the model. Structure: pass 1
   cluster+order (IDs only, cheap), pass 2 narrate per chunk (parallel, and
   per-chunk output is cacheable/regenerable when a single chunk's hunks
   change on force-push; key the cache on the hunk-content hash set per
   chunk).
10. **If you eval, eval behaviorally.** Graphite's lesson: line-range
    validation + accept/upvote signals, not synthetic scores. For a personal
    tool the minimum viable version is the coverage validator (item 2) plus
    "did I have to open the raw diff anyway" as your own upvote signal.

## Key links

[Linear Diffs docs](https://linear.app/docs/diffs) ·
[CodeRabbit cohorts blog](https://www.coderabbit.ai/blog/coderabbit-review-reads-a-pr-how-author-would-explain-it) ·
[CodeRabbit walkthrough docs](https://docs.coderabbit.ai/pr-reviews/walkthroughs) ·
[guidedreview repo](https://github.com/nshntarora/guidedreview) ·
[PR-Agent describe prompt](https://github.com/qodo-ai/pr-agent/blob/main/pr_agent/settings/pr_description_prompts.toml) ·
[Braintrust on Graphite](https://www.braintrust.dev/blog/graphite) ·
[ClusterChanges](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/barnett2015hdh.pdf) ·
[SmartCommit](https://www.cs.cmu.edu/~ckaestne/pdf/fse21_sc.pdf) ·
[File-ordering study](https://arxiv.org/abs/2306.06956) ·
[Contextualized reviews vision](https://arxiv.org/html/2402.09528) ·
[Diff→NL hallucination study](https://arxiv.org/html/2508.08661v1)

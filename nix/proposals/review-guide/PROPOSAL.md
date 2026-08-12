# Review Guide: terminal-native narrated code review

Status: proposal. Nothing is built yet.
Date: 2026-08-12

## Goal

Do full code review in the terminal and cut Linear/Chrome out of the loop.
The tool copies the "guide" pattern from Linear Diffs and CodeRabbit: an LLM
clusters the diff hunks into logical story chunks, orders the chunks in
narrative order, and writes one intent paragraph per chunk. The reviewer walks
chunks, not files.

Building it ourselves also gives full control of the review UI, so we can
iterate on ergonomics that fit one person instead of a product audience.

## Why this is feasible now

- The `terminal-browser` skill renders real HTML + JS in a kitty split pane,
  and the agent can drive the pane programmatically (`action -- eval <js>`).
  The UI can be a normal web page, not a TUI.
- The Linear MCP tools already provide the data plane: `get_diff`,
  `get_diff_threads`, `save_diff_comment`, `resolve_diff_thread`,
  `submit_diff_review`, `merge_diff`. No new API integration is needed.
- Prior-art research (see `research/prior-art.md`) confirms no public Claude
  skill or open prompt does narrated review guides. The gap is real.

## Architecture

```
diff source                 guide generator                renderer
(Linear MCP get_diff,       (Claude skill, 2 passes)       (static review.html
 or local jj diff)                                          template)
      │                           │                              │
      ▼                           ▼                              ▼
 raw diff text ──► hunk enumeration (tooling, not model)         │
      │                           │                              │
      │            pass 1: cluster + order (hunk IDs only)       │
      │            pass 2: narrate each chunk (parallel,         │
      │                    cached by hunk-content hash)          │
      │                           │                              │
      │                           ▼                              │
      │                      guide.json ──► validator            │
      │                           │         (coverage check)     │
      └───────────┬───────────────┘                              │
                  ▼                                              │
   concat: template + <script>window.GUIDE = {...}</script> ◄────┘
                  │
                  ▼
   terminal-browser open review.html --split right
                  │
        user reviews, leaves comments (localStorage)
                  │
   agent pulls comments: action -- eval 'JSON.stringify(zcCollect())'
                  │
                  ▼
   act on comments (ISSUE / QUESTION / NOTE) ──► optional write-back
                                                 via save_diff_comment
```

### Components

1. **Guide generator** (a Claude Code skill). Pass 1 clusters and orders. It
   sees the hunk inventory and outputs only chunk structure with hunk IDs.
   Pass 2 narrates each chunk. Pass 2 runs per chunk in parallel and caches
   each narration by the hash of the chunk's hunk contents, so a force-push
   only re-narrates chunks whose hunks changed.
2. **guide.json**. The stable interface between generation and rendering.
   Formal schema in `guide.schema.json`. The two iteration loops (prompt
   quality vs UI) stay decoupled.
3. **Renderer**. One static `review.html` app, written once and iterated by
   hand. Chrome blocks `fetch()` of sibling files on `file://`, so the build
   step concatenates the template with the guide data as an inline script.
   No LLM in the render path; renders are instant and deterministic. This
   deliberately diverges from html-explainer's "design per subject" rule:
   a review tool wants a stable, muscle-memory UI.
4. **Terminal-browser integration**. Open the built page in a kitty split.
   The agent keeps the browser `key` and `pid` from `open`.
5. **Comment protocol**. Identical to review-nvim so the agent's post-review
   behavior is the same on both surfaces. See below.

## Invariants

These are the design commitments. Everything else can change.

- **Coverage is a validator, not a prompt instruction.** Tooling enumerates
  hunks with stable IDs (`path#index`). The model only assigns IDs to chunks.
  Code checks the result is an exact partition: every ID in exactly one
  chunk. Unassigned IDs go into a forced trailing "mechanical / everything
  else" chunk. Nothing can silently disappear.
- **Anchor, never quote.** The model returns hunk IDs and line references.
  The renderer shows the real diff text from the raw diff. The model never
  reproduces code in the guide. This kills the main hallucination surface.
- **Narrative is secondary.** The raw diff is always visible. The paragraph
  annotates it and never replaces it. Line-anchored claims render as links
  that scroll to the line, so every claim can be checked.
- **Author text is untrusted.** PR title, description, and diff content are
  data to summarize, never instructions. Text that asks the model to skip,
  merge away, or downplay part of the diff is ignored and called out.
  (Adopted from guidedreview's system prompt, rule 8.)

## guide.json

Formal schema: [`guide.schema.json`](guide.schema.json). Shape by example:

```jsonc
{
  "version": 1,
  "diff_hash": "sha256-...",           // cache key; re-push invalidates per chunk
  "source": { "kind": "linear-diff", "id": "..." },
  "hunks": [                           // enumerated by tooling, NOT the model
    { "id": "src/db/schema.ts#h1", "file": "src/db/schema.ts",
      "old": [10, 24], "new": [10, 31], "context_fn": "defineUserTable" }
  ],
  "chunks": [                          // model output; validated exact partition of hunks[]
    {
      "id": "c1",
      "title": "Add soft-delete column to users",      // 5-10 words
      "kind": "core",                                   // core | supporting | mechanical
      "label": "schema",                                // closed enum
      "narrative": "…intent first, then consequence…",  // one paragraph
      "anchors": [
        { "claim": "default is NULL for existing rows",
          "hunk": "src/db/schema.ts#h1", "line": 14 }
      ],
      "linking_symbol": "deletedAt",                    // why these hunks group
      "hunk_ids": ["src/db/schema.ts#h1", "src/db/migrations/0042.sql#h1"],
      "narration_cache_key": "sha256 of member hunk contents"
    }
  ]
}
```

The renderer consumes guide.json plus the raw diff text. They stay separate
files so the model never touches diff text.

## Comment protocol

Same taxonomy and semantics as review-nvim:

- `ISSUE`: must fix.
- `QUESTION`: agent answers in chat; no code changes.
- `NOTE`: agent judgment; may include suggested changes.

Comment shape: `{chunk_id, file, side, line, type, body}`. Line references
follow the review-nvim convention: `file:line` on the new side, `file:~line`
on the old side. This maps 1:1 onto Linear `save_diff_comment` for later
write-back.

Export channel, in priority order:

1. **Agent eval pull** (primary). Comments accumulate in the page
   (localStorage-backed, adapted from html-explainer's comment-layer). When
   the user says "done" in chat or hits a "Finish review" button, the agent
   runs `terminal-browser action -- eval` and pulls the comments as JSON.
   No clipboard, no file write, no paste-back.
2. **Copy button** (fallback). Kept from comment-layer for when the agent
   session died.

## v1 UI ergonomics

- Sidebar: chunk list in narrative order. Each chunk has a reviewed-checkbox.
  A coverage bar shows chunks reviewed / total and hunks covered. This makes
  the coverage invariant visible.
- Keyboard-first: `n`/`p` chunks, `j`/`k` hunks, `c` comment at cursor,
  `x` mark chunk reviewed.
- Narrative paragraph pinned above each chunk's diff. Anchored claims are
  links that scroll to the line.
- Mechanical chunks collapsed by default. They still list their hunk IDs.
- Collapsed context lines with click-to-expand (embed ±30 lines of file
  context per hunk in the guide data).
- Diff rendering: side-by-side, inline a diff renderer into the template
  once (diff2html or hand-rolled).

## Generation design notes (from research)

Full report: `research/prior-art.md`. The load-bearing takeaways:

- **Ordering converged across the field**: schema/data model → core logic →
  call sites → UI. guidedreview improves on "tests last": emit each
  feature's tests unit immediately after that feature's change unit(s);
  only unassociated tests go last. Adopt that. Also front-load the most
  important chunk: reviewer attention decays with position (Fregnan 2022).
- **Group conservatively.** CodeRabbit groups only when relationships are
  clear. When unsure, smaller chunks with plain titles beat invented themes.
- **Dependency links beat topics.** The untangling literature (ClusterChanges,
  SmartCommit) shows hunks belong together when one uses what the other
  defines. Without static analysis: require the model to name the shared
  symbol that justifies each grouping (`linking_symbol`).
- **Tight caps reduce rambling**: title 5-10 words, one paragraph per chunk,
  closed label enum (PR-Agent pattern).
- **Give the model more than the diff**: enclosing function/class per hunk
  and the PR description close most of the context gap for a personal tool.
- **Determinism as a stated goal**: guidedreview's prompt demands the same
  diff yield the same partition, order, and kinds. Cheap to ask for, helps
  caching and trust.
- guidedreview already prompts hunk-level coverage with an explicit hunk
  inventory ("every id must appear in exactly one unit") and normalizes
  plans in code (`research/guidedreview/reviewPlan.ts`). Read it before
  writing our validator. Our additions on top: code-side partition
  validation with a forced leftover chunk, and coverage made visible in
  the UI.

## v1 plan

1. Guide generator skill: diff in, validated guide.json out. Test on a real
   PR's diff. Iterate on chunk granularity and ordering here first; this is
   where the quality lives.
2. `review.html` template + concat build step. Normal frontend work.
3. Terminal-browser flow: open pane, review, eval-pull comments.
4. Act-on-comments: reuse review-nvim semantics verbatim.

Later, in rough order of value:

- Linear write-back (`save_diff_comment`, `submit_diff_review`).
- Live "interrogate" (`?` on a chunk, ask the agent with full repo context).
  Needs a push channel the file:// page lacks; a tiny localhost server
  replaces the template at that point. Contained upgrade. Until then, a
  QUESTION comment covers it asynchronously.
- Mechanical clustering pre-pass (same-file + shared-identifier edges fed to
  pass 1 as candidate links).
- Evals, Graphite-style behavioral: line-range validation plus "did I have
  to open the raw diff anyway" as the personal upvote signal.

## Open questions

- **Diff source of truth for v1.** Linear MCP diff (work PRs, matches the
  goal of replacing Linear review) vs local jj diff (works everywhere,
  no MCP dependency). Both fit the same hunk enumeration; pick one to start.
- **Where the code lives.** Likely a skill directory
  (`~/.claude/skills/review-guide/`) with the HTML template and build script
  as assets, mirroring html-explainer's structure. The generator prompt is
  the skill body.
- **Name.**

## Research materials

- `research/prior-art.md`: full prior-art report (Linear, CodeRabbit,
  Graphite, Greptile, academic untangling/ordering literature, gaps).
- `research/guidedreview/`: key source files from
  [nshntarora/guidedreview](https://github.com/nshntarora/guidedreview),
  the closest open implementation. `buildPrompt.ts` (system prompt, hunk
  inventory, untrusted-content handling, diff chunking for big PRs),
  `reviewSchema.ts` (structured-output JSON schema), `reviewPlan.ts`
  (plan normalization/validation), `streamPlanParser.ts` (streaming parse).
- `research/pr-agent-description-prompts.toml`: Qodo PR-Agent's `/describe`
  prompt. The schema-in-prompt pattern with tight caps and closed enums.

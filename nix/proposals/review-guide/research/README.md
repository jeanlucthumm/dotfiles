# Research materials

Downloaded 2026-08-12 as supporting material for `../PROPOSAL.md`.

- `prior-art.md` — web research report on narrated review guide tooling
  (Linear, CodeRabbit, Graphite, Greptile, academic untangling and ordering
  literature) plus distilled design guidance.
- `guidedreview/` — key source files from
  [nshntarora/guidedreview](https://github.com/nshntarora/guidedreview)
  (main branch, 2026-08-12), the closest open implementation of guided
  review. License in `guidedreview/LICENSE`. Files:
  - `buildPrompt.ts` — system prompt (ordering rules, hunk inventory,
    untrusted-content rule 8), file-aligned diff chunking for big PRs.
  - `reviewSchema.ts` — structured-output JSON schema for the review plan.
  - `reviewPlan.ts` — plan normalization and validation. Read before
    writing our coverage validator.
  - `streamPlanParser.ts` — streaming parse of plan output.
  - `README.md` — upstream readme.
- `pr-agent-description-prompts.toml` — Qodo PR-Agent `/describe` prompt
  ([source](https://github.com/qodo-ai/pr-agent/blob/main/pr_agent/settings/pr_description_prompts.toml),
  main branch, 2026-08-12). Schema-in-prompt pattern with tight caps and
  closed label enums.

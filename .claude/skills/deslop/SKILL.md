---
name: deslop
description: Remove the residue of AI-written code (needless comments, defensive over-checking, thin wrappers, reinvented helpers, type escapes) without changing behavior. Trigger on "deslop", "remove the slop", "clean up what the agent wrote", or before marking an agent-written PR ready. Not for bug review (two-lens-review) or feature refactors.
---

The bar: every line earns its place, and the result reads like a principal
engineer wrote it for a reader with no context. What to cut and what to keep
is in `cut-keep.md`; every agent below gets it.

1. **Fence the scope.** The branch's own changes vs its real base (jj:
   `trunk()..@`; git: merge-base with the upstream, never assume `main`), or a
   path if given. Record the file list. Pre-existing slop outside the fence is
   reported, not edited. An empty fence is a valid no-op.
2. **Baseline.** Run the repo's typecheck, lint, and tests for the fenced
   files. Without a green baseline, only comment edits are allowed.
3. **Nominate.** Run whatever detectors the repo has (linters, knip/vulture,
   jscpd, `tsc --noUnused*`) on the fence. Their hits are candidates, not
   verdicts.
4. **Review.** Three read-only subagents in parallel, one lens each: comments
   and model-facing text; dead, defensive, and type-escape code; structure
   (reuse, wrappers, altitude). Each gets the fence, the detector hits, and
   `cut-keep.md`, and returns findings as `{file, line, kind, evidence}` where
   evidence answers "what breaks if this is deleted" (callers, types,
   boundary). They never edit.
5. **Apply, one lens at a time,** safest first: comments, then dead/defensive,
   then structure. You are the only writer. Re-check each finding against the
   current code; subagent claims are leads. After each lens, rerun the
   baseline checks and revert that lens's edits if anything goes red.
6. **Self-audit the diff** for new suppressions, casts, weakened tests, test
   deletions without the evidence `cut-keep.md` asks for, or anything else
   that games a check. Undo it.

Report: cut by category, flagged or asked about but left (with reason), and
anything you couldn't verify.

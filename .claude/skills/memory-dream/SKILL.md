---
name: memory-dream
description: Consolidation ("dream") pass over one ~/memory/projects folder: refresh stale index lines, merge duplicates, archive spent content. Explicit use only: /memory-dream <folder>.
disable-model-invocation: true
---

Consolidate the memory folder in $ARGUMENTS (a `~/memory/projects/<name>` dir; ask if missing).

## Operations

- Merge duplicated facts into their one home; fix contradictions at the source.
- Relative dates become absolute.
- Retire stale or superseded content to `_archive/<today>.md` instead of deleting: verbatim block quote plus a one-line provenance note, and update pointers to it. Retiring a whole file cites the doc's own admission bar.
- A fact with no home in its doc (unsourced, undated, off-topic) moves to the archive with an origin note. Don't trust it in place, don't delete it.
- Refresh `## Index` in the root and subdir AGENTS.md/CLAUDE.md maps: one line per entry, matching reality. Index `_archive/` and standalone artifacts (HTML) too.

## Rails

- Freshness: before writing ANY index or summary line, refreshed or newly added, read its source doc to the latest dated entry. Every error seen in testing was a line written from a partial read.
- Coverage: check every root index line against its source doc. Keep a checklist; skip nothing silently.
- Fix dead references. Leave "See its CLAUDE.md" pointers alone when CLAUDE.md symlinks to AGENTS.md.
- Small itemized edits; never rewrite a whole file.
- Status tables get the corrected value plainly, no "(previously: ...)" notes.
- Edit only `.md` files inside the target. Don't stage or commit; the ~/memory sync job does.

## Report

Index lines checked vs changed, merges, contradictions fixed, items archived, dead links fixed. A near no-op is fine.

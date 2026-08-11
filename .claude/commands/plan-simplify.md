Cleanup pass on a memory/plan doc (the one under discussion, or $ARGUMENTS).
Docs written incrementally accumulate cruft the author can't see — you wrote
it, you'll defend it. So the review is a fresh-context subagent; you only
apply.

Spawn one general-purpose subagent with: the doc path, the sibling docs and
what each OWNS (so it can judge one-home-per-fact), and these criteria:

1. Final-state wording — no decision narration or date stamps ("settled
   2026-08-11", "amended after X was disproven"). Provenance stays only when
   load-bearing (stops re-litigation). History belongs in the work log.
2. One home per fact. Restated content → pointer. Exception: a one-line
   restatement that saves the reader a file hop. Flag facts that exist ONLY
   in the wrong doc — those get MOVED to the owner, never deleted.
3. Internal redundancy: things said twice, contradictions, text a later
   section obsoleted.
4. Register: instructions carry their why briefly, don't defend themselves.

Have it return numbered findings — quote, criterion, suggested rewrite,
debatable ones flagged with the counterargument — no edits. Empty list is a
valid outcome.

Then apply with judgment: clear-cut findings yes, debatable ones your call
(say which you kept and why). Rehome orphaned facts first, trim second.

---
name: stepwise-explainer
description: Step through anything with Jean-Luc one small visual card at a time, paced by his acks, in a terminal-browser split pane. Owns the deck mechanic only; the caller (another skill like pr-walkthrough, or the conversation) decides what the cards contain. Bare invocations default to teaching a system or design.
disable-model-invocation: true
---

# Stepwise explainer

Why this works when a finished explainer doesn't: the sequencing and pacing live
in the conversation, so each visual only has to carry ONE idea, and he controls
depth by acking or asking. The cards orient; the chat teaches.

This skill is the mechanic only. What the cards contain is the caller's
business (teaching a design, walking a PR diff, ...); invoked bare, default to
teaching.

- Plan the arc first (5-8 beats), tell him the list, then one card per beat.
  Advance only on ack.
- Cards: single-file HTML in the job tmp dir, ~100 lines, plain SVG/CSS, no
  libraries. One idea, big text, consistent styling, "N of M" kicker (e.g.
  "Lesson 3 of 7"). Show via one reused pane — follow the `terminal-browser`
  skill.
- Narration in chat: a few plain sentences per card. If jargon slips and he
  asks, translate and re-teach; that's signal, not failure.
- Detours are the best part. Answer follow-ups fully, add bonus cards (2b, 4b),
  spawn research subagents for questions neither of you can answer, and fold
  what emerges into the project's memory docs as you go.
- Keep verified vs inferred marked — he'll carry these claims into meetings.

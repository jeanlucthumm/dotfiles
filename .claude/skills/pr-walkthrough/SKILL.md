---
name: pr-walkthrough
description: Guided review of a PR or diff as narrated cards in the terminal browser, paced by Jean-Luc. Trigger on "walk me through this PR/diff", "guided review", "/pr-walkthrough". NOT for autonomous review (code-review, two-lens-review), solo line-level review (review-nvim), or queue triage (review-buddy).
---

# PR walkthrough

Walk Jean-Luc through a diff as a card deck. Follow the `stepwise-explainer`
skill for the mechanic (arc, one pane, ack pacing); this skill only says what
the cards are.

- Diff source: whatever the session is about (local jj diff, Linear MCP
  `get_diff`, gh).
- Card 1: overview. All the pieces and how they hang together.
- Then deep dives in dependency order: schema/data model → core logic → call
  sites, with tests right after the feature they test. Real code samples
  welcome; simplifying a sample to its important parts is encouraged when
  that reads better. Mark simplified samples as such.
- He drops comments in chat between cards. Act on them as they come (fix,
  answer, push back); don't queue them for the end.
- Last card: "not covered". Every file/hunk that got no card, so nothing is
  skipped silently. Empty is the goal; anything listed gets looked at raw.

This skill is deliberately minimal and expected to grow. Endgame ideas
(guide.json schema, coverage validation, in-page comments) are parked in
`~/nix/proposals/review-guide/`.

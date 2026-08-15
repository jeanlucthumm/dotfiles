---
name: approve
description: Get micromanager approval for a PR via the bot-review-clean path.
argument-hint: [one-line reason]
disable-model-invocation: true
---

Micromanager approval stands in for a human review, so only request it when
the automated reviewers came back clean. Check first, in one pass:

1. Codex: `gh pr checks <n>` must show the Codex threshold check passing
   ("No findings at or above ... threshold").
2. No unresolved review threads and no CHANGES_REQUESTED reviews (arbiter or
   otherwise) via the GraphQL reviewThreads query.

If anything is outstanding, STOP and report what's open instead of commenting.

If clean, comment on the PR:

```
@replit/micromanager approve <one-line reason>
```

The reason MUST come from the arguments. Do not invent a reason ever. If you
don't have one, ask the user.

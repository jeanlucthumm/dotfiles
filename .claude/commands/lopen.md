---
description: Open the current PR's review in the Linear desktop app
---

Take the PR's GitHub URL (it's almost always already in conversation; else
`gh pr view --json url -q .url`). Linear resolves any GitHub PR URL with
`github.com` swapped for `linear.review`, which redirects to the workspace's
review page, so no API or MCP call is needed:

1. Rewrite `https://github.com/<owner>/<repo>/pull/<n>` to
   `linear://review/<owner>/<repo>/pull/<n>` and `open` it.
2. Print the `https://linear.review/...` form of the URL (clickable fallback).

If the deep link doesn't land (e.g. no review exists for the PR), print the
GitHub URL instead.

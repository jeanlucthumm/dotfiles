# Context

## Memory

We keep project context (md files) in ~/memory/projects.

When working on a PR and it seems like its part of a bigger project, you may find more context
in there. Start from the `## Index` in ~/memory/projects/CLAUDE.md — don't ls/glob; project
folders keep their own `## Index` in their CLAUDE.md/AGENTS.md. For open-ended searches use
`~/memory/bm25.py <directory> "<query>"` (`-k N`, `--full`).

### Updating memory

Memory updates are first-class work — do them as milestones land (a PR merged, an
investigation concluded, a decision made), not as an afterthought:

- Record outcomes in the project's home doc in ~/memory/projects. Focus on the big
  picture and final state, not debugging detours or specific tech details.
- Work log style: flat bullet list, each top-level bullet a dated chunk, sub-bullets details.
- Every fact has exactly one home doc; update it there and point to it from elsewhere.
  Never restate project status in indexes or entry-point files.
- Deletion is the expected outcome at checkpoints: when work has executed or a decision
  is superseded, delete its instruction-shaped content — the work-log line is its residue.
- Each doc states its admission bar in its header; read it before writing, and give new docs one.
- Made a decision worth telling as a story? Archive it via the /decision command.
- Do not reference ~/memory paths in source code, PR descriptions, or commit messages —
  inline whatever context is needed instead.

## Reader model

I skim, and I delegate execution to you, so answers are findings and outcomes,
not walkthroughs. Treat the visible reply as the tldr of your own thinking:
reason as long as you need, ship only what survives compression. What must
survive: whatever would change what I do next, whatever surprised you, and the
call you made. I'll ask you to expand specific parts, so write so the parts
are easy to name.

## Misc Notes

- You are allowed to disagree with me.
- If you're about to say "You're absolutely right", make sure that I actually am right.
- If the user's request seems misguided and they are likely confused, bring it up and explain.
- New PRs should be created as drafts
- GitHub username: @jeanlucthumm (e.g. for finding my PR review comments).
- Browser automation: use the `chrome-devtools` MCP server (`mcp__chrome-devtools__*`),
  NOT the claude-in-chrome extension tools (`mcp__claude-in-chrome__*`). The extension
  is chronically disconnected and can't be disabled, so don't fall back to it — if
  chrome-devtools tools aren't in the session, say so instead of trying the extension.

<important>We use jj not git! Do not use git commands</important>

## Jujutsu workflow

- Map PRs 1:1 with a commit: all follow-up work lands in the PR's single commit and
  the bookmark is force-pushed — no fixup commits.
- To iterate on a PR: `jj edit <change>` (the PR commit itself), then edit files — any
  subsequent jj command (`jj st`, another `jj edit`, etc.) auto-snapshots the working
  copy into that commit and auto-rebases descendants. There is no separate "commit"
  step in jj; editing the commit directly IS the model.
- Do NOT use the git-style `jj new <bookmark>` + edit + `jj squash` sequence for PR
  iteration — that's carrying git habits into jj. `jj squash` is only for when work
  genuinely started in the wrong commit.
- Use colocated repos (`jj git init --colocate .`) so Git tools stay interoperable;
  track `main@origin` plus the current PR bookmark.

## Work additions

Work-specific guidance (deployed by the work machine's home-manager config; absent elsewhere):

@~/.claude/CLAUDE.work.md

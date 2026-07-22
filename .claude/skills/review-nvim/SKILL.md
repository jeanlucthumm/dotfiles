---
name: review-nvim
description: Pop an LSP-enabled Neovide code-review window for a jj workspace PR and auto-act on the comments when the user closes it. Trigger when the user says things like "lemme review in neovim", "open this in nvim", "let me look at the diff myself", "spin up a review window", or invokes /review-nvim. Works in any jj-colocated repo with .claude/worktrees workspaces.
---

# review-nvim

Launch a human code review of a jj workspace's PR commit in Neovide via
`review-pr`, then act on the comments that come back.

## Steps

1. **Pick the target workspace.** Infer it: the workspace this conversation is
   about, or the session's own worktree. If several are plausible, list
   candidates (`jj workspace list`) and ask. The target is a name under
   `<repo>/.claude/worktrees/` or a path to a jj workspace.

2. **Launch in background Bash** (never blocking the conversation):

   ```
   review-pr --spawn <workspace-name>
   ```

   A bare workspace name resolves relative to the CURRENT directory, so when
   the session's cwd is already inside a worktree (background sessions usually
   are), the name nests and fails with "no jj workspace at
   .../<ws>/.claude/worktrees/<ws>". Pass the absolute workspace path instead:
   `review-pr --spawn <repo>/.claude/worktrees/<workspace-name>`.

   If `review-pr` is not on PATH (home config not rebuilt yet), build it ad hoc:

   ```
   nix build --impure --expr 'let f = builtins.getFlake "path:/Users/jeanlucthumm/nix"; pkgs = import f.inputs.nixpkgs { system = "aarch64-darwin"; }; in pkgs.callPackage /Users/jeanlucthumm/nix/autoimport/packages/_derivations/review-pr.nix {}' -o /tmp/review-pr-bin
   /tmp/review-pr-bin/bin/review-pr --spawn <workspace-name>
   ```

3. **Tell the user the window is up** (one line: workspace, base rev), then
   keep working or chatting. Do not poll; the background task completes when
   they close the editor (`q`) and its stdout contains the review comments.

4. **When the comments arrive, act on them without being asked:**
   - `ISSUE`: must fix.
   - `QUESTION`: answer inline in chat; do not change code for these.
   - `NOTE`: use judgment; may include suggested changes.
   - `No comments. Review finished with nothing to address.` means a clean
     review: say so and move on.
   Report back what was fixed/answered when done. Remember comments reference
   `file:line` on the new side and `file:~line` on the old side of the diff.

## Debugging

- The nvim instance listens on `/tmp/review-pr-<name>.sock`; drive it with
  `nvim --server <sock> --remote-expr/--remote-send`. Verify LSP with a real
  request (hover/documentSymbol), not client attachment.
- Known gotchas (left pane has no LSP by design, tsserver OOM fix, statusline
  shows only progress) are in the `nvim-review-flow` memory for this project.

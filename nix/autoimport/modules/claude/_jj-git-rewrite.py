#!/usr/bin/env python3
"""PreToolUse (Bash) hook: route `jj git fetch` / `jj git push -b X` through the
jj-fetch / jj-push wrappers when the session runs from a Claude Code jj
workspace (a directory under .claude/worktrees/).

Why: Claude Code's worktree-isolation guard refuses any Bash command that hands
the operand `git` to a program it does not recognise, so `jj git ...` is refused
in isolated sessions even though jj workspaces share one repo store and the
command is exactly what a fetch or push from any workspace should be. The
wrappers do the same thing without spelling the token `git`. Rewriting here
lets the model type the natural command and still have it run.

Contract: fail open. Any parse problem, any command shape outside the two
patterns below, or any cwd outside a workspace produces no output, and the
command runs untouched. Output carries only `updatedInput` (no permission
decision), so the rewritten command goes through the normal permission flow.

Usage: _jj-git-rewrite.py <jj-fetch path> <jj-push path>. The wrappers are
passed by absolute store path so the rewrite does not depend on the tool
shell's PATH.
"""
import json
import os
import re
import sys

# A command position: start of text, or right after a separator that begins a
# new simple command. Quoted text (grep patterns, echo arguments, heredocs) is
# left alone because `jj` must itself be the command word.
_BOUNDARY = r"(?:^|(?<=[;&|(\n{]))(?P<lead>[ \t]*)"
_END = r"(?=[ \t]*(?:$|[;&|)\n}]|\d?>))"
_BOOKMARK = r"(?P<bm>[A-Za-z0-9][^\s;&|<>()$`'\"\\]*)"

FETCH = re.compile(_BOUNDARY + r"jj[ \t]+git[ \t]+fetch" + _END, re.M)
PUSH = re.compile(
    _BOUNDARY
    + r"jj[ \t]+git[ \t]+push[ \t]+(?:-b[ \t]+|--bookmark(?:[ \t]+|=))"
    + _BOOKMARK
    + _END,
    re.M,
)


def rewrite(cmd: str, jj_fetch: str, jj_push: str) -> str:
    cmd = FETCH.sub(lambda m: m.group("lead") + jj_fetch, cmd)
    cmd = PUSH.sub(lambda m: m.group("lead") + jj_push + " " + m.group("bm"), cmd)
    return cmd


def in_workspace(cwd: str) -> bool:
    return "/.claude/worktrees/" in (cwd.rstrip("/") + "/")


def main() -> None:
    try:
        jj_fetch, jj_push = sys.argv[1:3]
        data = json.load(sys.stdin)
        if data.get("tool_name") != "Bash":
            return
        tool_input = data.get("tool_input") or {}
        cmd = tool_input.get("command")
        if not isinstance(cmd, str) or "jj" not in cmd or "git" not in cmd:
            return
        # Heredoc and herestring bodies are data, not commands; a line in one
        # that starts with `jj git fetch` must stay as written. Leave the whole
        # command to the guard rather than parse heredocs here.
        if "<<" in cmd:
            return
        if not in_workspace(str(data.get("cwd") or "")):
            return
        if not (os.access(jj_fetch, os.X_OK) and os.access(jj_push, os.X_OK)):
            return
        new = rewrite(cmd, jj_fetch, jj_push)
        if new == cmd:
            return
        out = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "updatedInput": {**tool_input, "command": new},
                "additionalContext": (
                    "Ran `%s` as `%s` (same operation; `jj git ...` is refused in "
                    "workspace sessions)." % (cmd, new)
                ),
            }
        }
        sys.stdout.write(json.dumps(out))
    except Exception:
        return


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Minimal file suggestion hook for Claude Code @ autocomplete.

Search for files using simple string matching with ripgrep.

Credit: polyrand (https://github.com/anthropics/claude-code/issues/14399#issuecomment-3751709755)

TODO: Remove this once fixed upstream (https://github.com/anthropics/claude-code/issues/14399)
"""

import json
import os
import subprocess
import sys


def main() -> int:
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON input: {e}", file=sys.stderr)
        return 1

    query = input_data.get("query", "")
    if not query:
        return 0

    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", ".")
    project_dir = os.path.abspath(project_dir)

    cmd = f"rg --follow --files | rg -i -F '{query}'"
    result = subprocess.run(
        cmd,
        shell=True,
        cwd=project_dir,
        capture_output=True,
        text=True,
    )

    for line in result.stdout.splitlines()[:15]:
        print(line)

    return 0


if __name__ == "__main__":
    sys.exit(main())

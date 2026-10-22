#!/usr/bin/env bash
# Usage: zc-bridge-reply.sh <n> [port] < answer.md
# Queues stdin (light markdown) as Claude's reply in comment C<n>'s thread; the
# page picks it up on its next poll. `zc-bridge-reply.sh reload` reloads the page.
port=${2:-47321}
if [ "$1" = reload ]; then
  curl -fsS -X POST --data '{}' "http://127.0.0.1:$port/session/reload" >/dev/null
else
  jq -Rs --argjson n "$1" '{n: $n, md: .}' | curl -fsS -X POST --data-binary @- "http://127.0.0.1:$port/session/answer" >/dev/null
fi

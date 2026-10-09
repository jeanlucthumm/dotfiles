#!/usr/bin/env bash
# Usage: zc-live-reply.sh <browser-key> <n> < answer.md
# Renders stdin (light markdown) as Claude's reply in comment C<n>'s thread.
terminal-browser action --browser "$1" -- eval "zcLive.answer($2, $(jq -Rs .))"

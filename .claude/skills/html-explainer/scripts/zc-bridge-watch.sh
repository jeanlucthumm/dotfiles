#!/usr/bin/env bash
# Usage: zc-bridge-watch.sh [port]. Run under Monitor. The plain-browser twin of
# zc-live-watch.sh: drains the local relay (zc-bridge-server.py) every 1.5 s,
# which is also what lights the page's "live" badge, and prints one JSON line
# per new comment or follow-up. Exits with a {"closed":...} line if the relay dies.
port=${1:-47321}; fails=0
while :; do
  if out=$(curl -fsS --max-time 5 "http://127.0.0.1:$port/session/drain" 2>&1); then
    fails=0; jq -c '.items[]?' <<<"$out"
  elif (( ++fails >= 5 )); then
    jq -cn --arg e "$out" '{closed: true, error: $e}'; exit 1
  fi
  sleep 1.5
done

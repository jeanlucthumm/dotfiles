#!/usr/bin/env bash
# Usage: zc-live-watch.sh <browser-key>. Run under Monitor: polls the page's
# comment layer (which also keeps its "live" badge on) and prints one JSON line
# per new comment or follow-up. Exits with a {"closed":...} line if the pane dies.
key=$1; fails=0
while :; do
  if out=$(terminal-browser action --browser "$key" -- eval 'JSON.stringify(window.zcLive ? zcLive.drain() : null)' 2>&1); then
    fails=0
    jq -c 'fromjson | .[]?' <<<"$out" 2>/dev/null
  elif (( ++fails >= 5 )); then
    jq -cn --arg e "$out" '{closed: true, error: $e}'; exit 1
  fi
  sleep 1.5
done

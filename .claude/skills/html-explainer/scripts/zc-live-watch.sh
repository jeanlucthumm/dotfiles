#!/usr/bin/env bash
# Usage: zc-live-watch.sh <browser-key>. Run under Monitor: polls the page's
# comment layer (which also keeps its "live" badge on) and prints one JSON line
# per new comment or follow-up. Exits with a {"closed":...} line if the pane dies.
#
# Polls go straight to terminal-browser's bundled agent-browser. Every
# `terminal-browser action` call re-lights the pane's blue "agent is driving"
# outline for 10s, so polling through it kept the outline on for good. `action`
# is only used to (re)connect, which picks this pane's tab. All panes share one
# debugging port, so a token in the tab's sessionStorage stops a direct poll
# from draining another pane's page if agent-browser ever switches pages.
key=$1; fails=0
info=$(terminal-browser ls --all --json 2>/dev/null | jq -c --arg k "$key" '.browsers[]? | select(.key == $k)')
if [ -z "$info" ]; then jq -cn --arg k "$key" '{closed: true, error: ("no browser " + $k)}'; exit 1; fi
port=$(jq -r .cdpPort <<<"$info")
session="terminal-browser-$key"
AGENT_BROWSER_SOCKET_DIR="$(dirname "$(dirname "$(jq -r .socket <<<"$info")")")/agent-browser"
export AGENT_BROWSER_SOCKET_DIR
ab=${TERMINAL_BROWSER_AGENT:-"$(dirname "$(dirname "$(readlink -f "$(command -v terminal-browser)")")")/agent-browser/bin/agent-browser"}

token="zc-watch-$$-$RANDOM"
poll="(() => { try { if (sessionStorage.getItem('zc-watch') !== '$token') return 'stale'; } catch (e) { return 'stale'; }
  return JSON.stringify(window.zcLive ? zcLive.drain() : null); })()"
claim="(() => { try { sessionStorage.setItem('zc-watch', '$token'); } catch (e) {}
  return JSON.stringify(window.zcLive ? zcLive.drain() : null); })()"

connected() { local pid; pid=$(cat "$AGENT_BROWSER_SOCKET_DIR/$session.pid" 2>/dev/null) && kill -0 "$pid" 2>/dev/null; }
emit() { jq -c 'fromjson | .[]?' <<<"$1" 2>/dev/null; }

while :; do
  if connected && out=$("$ab" --session "$session" --cdp "$port" eval "$poll" 2>&1) && [ "$out" != '"stale"' ]; then
    fails=0; emit "$out"
  elif out=$(terminal-browser action --browser "$key" -- eval "$claim" 2>&1); then
    fails=0; emit "$out"
    terminal-browser action --browser "$key" "done" >/dev/null 2>&1
  elif (( ++fails >= 5 )); then
    jq -cn --arg e "$out" '{closed: true, error: $e}'; exit 1
  fi
  sleep 1.5
done

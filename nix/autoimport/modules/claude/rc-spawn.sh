#!/usr/bin/env bash
# Built by claude-rc.nix, which prepends rc-env.sh, sets $rc_dirs (unit name
# -> directory) and $rc_spawn_inner, and puts script(1) and jq on PATH.
#
# `claude --cloud` starts a session in the account's default cloud
# environment. Each `claude rc` unit registers as an environment too, so
# naming it as the default gives a session that runs on this host in the
# unit's directory and is listed in the app beside the ones started there.
# This is the only way in for a plain session: the create_session tool exists
# only inside sessions an rc unit spawned.
#
# If the ID names no live environment, `claude --cloud` silently starts the
# session on a cloud machine instead, so rc-spawn checks the ID before and
# the outcome after.

usage() {
  cat <<EOF
Usage: rc-spawn [--model MODEL] NAME PROMPT...
       rc-spawn [--model MODEL] NAME < prompt.txt

Starts a Remote Control session under the claude-rc-NAME unit, in auto
permission mode, and prints its session ID. The service writes the session's
title from the prompt, so lead with what the session is for.

MODEL is an alias (opus, sonnet, fable) or a full model name. Default: opus.
Opus models run at xhigh effort; others at their own default.

Exits 1 if no session was started, 3 if one was but not under the unit (it
then runs on a cloud machine, not this host: archive it).

Names: ${!rc_dirs[*]}

Message the session afterwards with: claude -p "MESSAGE" --cloud SESSION_ID
EOF
}

model=opus
case "${1:-}" in
  --model)
    [[ -n ${2:-} ]] || { usage >&2; exit 2; }
    model=$2
    shift 2
    ;;
  --model=?*)
    model=${1#--model=}
    shift
    ;;
esac
effort=
if [[ $model == *opus* ]]; then effort=xhigh; fi

name=${1:-}
shift || true
case "$name" in
  -h|--help) usage; exit ;;
  ""|-*) usage >&2; exit 2 ;;
esac
dir=${rc_dirs[$name]:-}
if [[ -z $dir ]]; then
  echo "rc-spawn: no rc unit named '$name' (have: ${!rc_dirs[*]})" >&2
  exit 2
fi

if [[ $# -gt 0 ]]; then prompt=$*; else prompt=$(cat); fi
[[ -n $prompt ]] || { usage >&2; exit 2; }

unit=claude-rc-$name
if ! systemctl --user is-active --quiet "$unit"; then
  echo "rc-spawn: $unit is not running" >&2
  exit 1
fi
if ! env_id=$(rc_record_id "$name"); then
  # Units started before they logged registrations only have the ID file,
  # good only if written after the unit's current start.
  id_file=$rc_ids/$name.environment
  started=$(systemctl --user show -P ActiveEnterTimestamp "$unit")
  if [[ ! -s $id_file ]] || (($(stat -c %Y "$id_file") < $(date -d "$started" +%s))); then
    cat >&2 <<EOF
rc-spawn: no current environment ID for $unit (started $started).
$id_file is missing or older than that start, so its ID is dead. In any
Remote Control session, run list_environments and write the ID of
"$HOSTNAME:$name:..." there. Units started by restart-claude-rc record it
themselves.
EOF
    exit 1
  fi
  env_id=$(<"$id_file")
fi

export RC_SPAWN_PROMPT=$prompt
export RC_SPAWN_MODEL=$model RC_SPAWN_EFFORT=$effort
RC_SPAWN_SETTINGS=$(jq -nc --arg id "$env_id" '{remote: {defaultEnvironmentId: $id}}')
RC_SPAWN_DEBUG=$(mktemp -t rc-spawn.XXXXXX)
trap 'rm -f "$RC_SPAWN_DEBUG"' EXIT
export RC_SPAWN_SETTINGS RC_SPAWN_DEBUG

# --cloud refuses to run without a terminal, so script(1) lends it one. The
# command is a store path, which any $SHELL runs as is.
cd "$dir"
status=0
out=$(timeout 120 script -qec "$rc_spawn_inner" /dev/null </dev/null 2>&1) || status=$?

id=$(grep -o 'session_[A-Za-z0-9]\+' <<<"$out" | head -n1 || true)
if [[ $status -ne 0 || -z $id ]]; then
  echo "rc-spawn: no session was started (exit $status):" >&2
  tr -d '\r' <<<"$out" | sed 's/\x1b[^a-zA-Z]*[a-zA-Z]//g' >&2
  exit 1
fi

# claude's debug log is the only place it says which environment it used.
if ! grep -qF "Using the configured default environment: $env_id" "$RC_SPAWN_DEBUG"; then
  selected=$(grep -o 'Selected environment: .*' "$RC_SPAWN_DEBUG" | tail -n1 || true)
  cat >&2 <<EOF
rc-spawn: session $id did not start under $unit ($env_id), so it
runs on a cloud machine, not $HOSTNAME. Archive it.
claude said: ${selected:-nothing about its environment}
EOF
  exit 3
fi
echo "$id"

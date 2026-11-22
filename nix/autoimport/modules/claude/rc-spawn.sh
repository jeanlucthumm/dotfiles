#!/usr/bin/env bash
# Built by claude-rc.nix, which sets $rc_dirs (unit name -> directory) and
# $rc_spawn_inner, and puts script(1) and jq on PATH.
#
# `claude --cloud` starts a session in the account's default cloud
# environment. Each `claude rc` unit registers as an environment too, so
# naming it as the default gives a session that runs on this host in the
# unit's directory and is listed in the app beside the ones started there.
# This is the only way in for a plain session: the create_session tool exists
# only inside sessions an rc unit spawned.

usage() {
  cat <<EOF
Usage: rc-spawn [--model MODEL] NAME PROMPT...
       rc-spawn [--model MODEL] NAME < prompt.txt

Starts a Remote Control session under the claude-rc-NAME unit, in auto
permission mode, and prints its session ID. The service writes the session's
title from the prompt, so lead with what the session is for.

MODEL is an alias (opus, sonnet, fable) or a full model name. Default: opus.
Opus models run at xhigh effort; others at their own default.

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

# The environment ID is host state, not nix: the service assigns it when the
# unit registers, nothing on disk records it, and it may change when the unit
# restarts.
id_file=${XDG_CONFIG_HOME:-$HOME/.config}/claude-rc/$name.environment
if [[ ! -s $id_file ]]; then
  cat >&2 <<EOF
rc-spawn: $id_file is missing or empty.
It holds the environment ID (env_...) of claude-rc-$name. Any Remote Control
session can look it up with its list_environments tool.
EOF
  exit 1
fi

export RC_SPAWN_PROMPT=$prompt
export RC_SPAWN_MODEL=$model RC_SPAWN_EFFORT=$effort
RC_SPAWN_SETTINGS=$(jq -nc --arg id "$(<"$id_file")" '{remote: {defaultEnvironmentId: $id}}')
export RC_SPAWN_SETTINGS

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
echo "$id"

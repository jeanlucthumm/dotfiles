# Sourced by rc-spawn and restart-claude-rc; claude-rc.nix sets $rc_state.
#
# Each start of a claude-rc unit registers a new environment (env_...) with
# the service and the previous one is deleted. The only local record of the ID
# is the unit's debug log, which ExecStartPre rotates on every start.

rc_ids=${XDG_CONFIG_HOME:-$HOME/.config}/claude-rc

# Prints the environment ID claude-rc-NAME registered on its current start
# and records it in $rc_ids/NAME.environment. Fails if nothing is logged yet.
rc_record_id() {
  local id
  id=$(grep -o 'Registered, server environmentId=env_[A-Za-z0-9]*' "$rc_state/$1/rc.log" 2>/dev/null | tail -n1 || true)
  id=${id##*=}
  [[ -n $id ]] || return 1
  mkdir -p "$rc_ids"
  echo "$id" >"$rc_ids/$1.environment"
  echo "$id"
}

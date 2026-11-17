# shellcheck shell=bash
# SessionStart hook (installed by claude-code.nix as claude-devenv-env): load
# the project's devenv into the session so every Bash call runs inside it, the
# way `use devenv` does for direnv. Claude Code pastes the text of
# $CLAUDE_ENV_FILE into the command string of every Bash call.

[ -n "${CLAUDE_ENV_FILE:-}" ] || exit 0
cd "$(jq -r .cwd)"
[ -f devenv.nix ] || exit 0

# The Bash tool runs zsh where Claude Code finds one (macOS) and bash
# otherwise (NixOS), so the output has to load in both. print-dev-env is a
# bash state dump: it assigns LINENO (read-only in zsh, aborts every Bash
# call) and defines bash-only function bodies. Let bash consume it and emit
# only exported variables. enterShell output goes to stderr so it can't land
# in the dump. CLAUDE_ENV_FILE is dropped so a claude started from a Bash call
# does not load this session's file as well. Captured before anything is
# written, so a devenv failure leaves the previous dump in place.
env=$(bash -c '
  dump=$(devenv print-dev-env) || exit
  eval "$dump" >&2
  export -p | grep -Ev "^declare -x (PWD|OLDPWD|SHLVL|_|CLAUDE_ENV_FILE)="
')

# The env file's text rides in the argv of every Bash call, so it has to stay
# tiny and free of secrets: one argument over 128 KiB fails the spawn with
# E2BIG, and argv is world-readable through ps. The dump runs to tens of KB
# and carries the whole session environment, API keys included, so it goes to
# a private sibling and the env file only sources it. The sibling's name must
# not match <event>-hook-<N>.sh, or Claude Code would inline it as well.
# SessionStart fires again on resume and /compact, so both writes replace,
# never append.
umask 077
out="${CLAUDE_ENV_FILE%/*}/devenv-env.sh"
# print-dev-env replaces PATH wholesale; keep the session's tools reachable
# behind the project's, as nix develop does.
# shellcheck disable=SC2016
printf '%s\nexport PATH="$PATH:%s"\n' "$env" "$PATH" >"$out"
printf '. %q\n' "$out" >"$CLAUDE_ENV_FILE"

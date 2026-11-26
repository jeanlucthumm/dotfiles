#!/usr/bin/env bash
# Built by email-triage.nix, which sets $claude, $dir (the vault's triage
# folder), $chores (the chore index), $state, $allowed, $denied, $settings
# and $schema, and puts jq and coreutils on PATH.

dry=
case "${1:-}" in
  "") ;;
  --dry-run) dry=1 ;;
  *)
    echo "Usage: email-triage [--dry-run]" >&2
    exit 2
    ;;
esac

mkdir -p "$state/logs"
find "$state/logs" -name '*.jsonl' -mtime +30 -delete
# Outside the vault, so the vault's CLAUDE.md chain stays out of the router's context.
cd "$state"

now=$(date +%s)
last=$(cat "$dir/last-run" 2>/dev/null || echo $((now - 12 * 3600)))
# The Gmail connector ignores after:<epoch> (returns nothing), but
# newer_than takes hours. Round up, with 5 minutes of overlap; duplicates
# are accepted.
hours=$(((now - last + 300 + 3599) / 3600))
query="in:inbox newer_than:${hours}h"

tools=("${allowed[@]}")
if [[ -n $dry ]]; then
  mode="DRY RUN"
else
  mode=LIVE
  tools+=(mcp__claude_ai_Gmail__unlabel_thread)
fi

prompt="$(cat "$dir/prompt.md")

## This run

- Mode: $mode
- Now: $(date '+%a %Y-%m-%d %H:%M %Z')
- Gmail query: \`$query\`

## Open chores

$(cat "$chores")"

log="$state/logs/$(date +%Y%m%d-%H%M%S)${dry:+-dry}.jsonl"

# Prompt first: the tool flags are variadic. User settings are skipped
# (--setting-sources project, and there is no project here): they carry
# auto mode, broad allow rules and hooks. dontAsk denies whatever isn't
# allowed below, so the allowlist is the boundary, plus the hub-only hook in
# $settings for SendMessage, which skips permission checks. The deny list only
# keeps the riskiest tools out of the model's sight.
"$claude" -p "$prompt" \
  --model haiku \
  --setting-sources project \
  --settings "$settings" \
  --permission-mode dontAsk \
  --tools ToolSearch ListAgents SendMessage \
  --allowedTools "${tools[@]}" \
  --disallowedTools "${denied[@]}" \
  --json-schema "$schema" \
  --max-budget-usd 2 \
  --no-session-persistence \
  --output-format stream-json --verbose \
  </dev/null >"$log" || echo "email-triage: claude exited $?" >&2

# Sent means a SendMessage to hub-* came back with success, not what the
# model says about itself.
sent=$(jq -s '
  [.[] | select(.type == "assistant") | .message.content[]?
    | select(.type == "tool_use" and .name == "SendMessage"
        and ((.input.to // .input.recipient // "") | startswith("hub-")))
    | .id] as $ids
  | [.[] | select(.type == "user") | .message.content[]?
      | select(.type == "tool_result" and (.tool_use_id as $i | $ids | index($i)))
      | .content | if type == "array" then map(.text? // "") | join("") else . end
      | (try fromjson catch {}) | .success == true]
  | any' "$log")

result=$(jq -c 'select(.type == "result")
  | {subtype, cost: .total_cost_usd, turns: .num_turns, out: .structured_output}' "$log")
echo "email-triage ($mode, $query): sent=$sent $result"

if [[ -n $dry ]]; then
  [[ $sent == true ]]
  exit
fi

list="$dir/Unsubscribe list.md"
added=0
while IFS=$'\t' read -r email line; do
  if ! grep -qiF "<$email>" "$list"; then
    echo "$line" >>"$list"
    added=$((added + 1))
  fi
done < <(jq -r 'select(.type == "result") | .structured_output.unsubscribe[]?
  | select((.email | test("^[^@\\s<>]+@[^@\\s<>]+$"))
      and (.link | test("^(https?://|mailto:)\\S+$")))
  | [.email, "- \((.name // "") | gsub("[\\n\\r\\t<>\\[\\]]"; "") | .[0:60]) <\(.email)>: \(.link)"]
  | @tsv' "$log")
echo "email-triage: $added added to the unsubscribe list"

if [[ $sent != true ]]; then
  echo "email-triage: no hub message went through; last-run not advanced" >&2
  exit 1
fi
echo "$now" >"$dir/last-run"

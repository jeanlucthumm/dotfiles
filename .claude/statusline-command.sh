#!/usr/bin/env bash
# Status line: show git repo name + branch, or fallback to basename of cwd

input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name')
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Change to the working directory
cd "$cwd" 2>/dev/null || { echo "$model"; exit 0; }

# Try to get git root and branch
git_root=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -n "$git_root" ]; then
  repo_name=$(basename "$git_root")
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "detached")
  location="$repo_name:$branch"
else
  # Fallback to basename of current directory
  location=$(basename "$cwd")
fi

# Build status line with context percentage if available
if [ -n "$used" ]; then
  context_str=$(printf "%.0f%%" "$used")
  echo "$model • $location • $context_str"
else
  echo "$model • $location"
fi

#!/usr/bin/env bash
input=$(cat)

cwd=$(echo "$input" | jq -r '.cwd // empty')
model_id=$(echo "$input" | jq -r '.model.id // empty')
COMPACT_WINDOW=200000
used=$(echo "$input" | jq -r "
  (.context_window.used_percentage // 0) as \$pct |
  (.context_window.context_window_size // 1) as \$total |
  (\$pct * \$total / 100 / $COMPACT_WINDOW * 100) | floor
")
tokens=$(echo "$input" | jq -r '
  (.context_window.used_percentage // 0) as $pct |
  (.context_window.context_window_size // 0) as $total |
  (($pct * $total / 100) / 1000) as $k |
  ($k * 10 | floor) / 10 | tostring + "k"
')

# Git branch
branch=""
if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
fi

# Derive model family from model ID
model=""
if [ -n "$model_id" ]; then
  case "$model_id" in
    *opus*)   model="Opus" ;;
    *sonnet*) model="Sonnet" ;;
    *haiku*)  model="Haiku" ;;
    *)        model="$model_id" ;;
  esac
fi

BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED_BG='\033[41;97m'
RESET='\033[0m'
SEP=' • '

dir_name=$(basename "$cwd")

# Line 1: {blue:dir} on {red:branch}
line1="${BLUE}${dir_name}${RESET}"

if [ -n "$branch" ]; then
  line1="${line1} on ${RED}${branch}${RESET}"
fi

# Line 2: {yellow:pct% • tokens} • {green:model}
line2=""
if [ -n "$used" ]; then
  if [ "$used" -gt 100 ]; then
    color="$RED_BG"
  else
    color="$YELLOW"
  fi
  line2="${color}${tokens} (${used}%)${RESET}"
fi

if [ -n "$model" ]; then
  if [ -n "$line2" ]; then
    line2="${line2}${SEP}${GREEN}${model}${RESET}"
  else
    line2="${GREEN}${model}${RESET}"
  fi
fi

if [ -n "$line2" ]; then
  printf "%b\n%b" "$line1" "$line2"
else
  printf "%b" "$line1"
fi

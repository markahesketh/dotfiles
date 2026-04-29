#!/usr/bin/env bash
input=$(cat)

cwd=$(echo "$input" | jq -r '.cwd // empty')
model_id=$(echo "$input" | jq -r '.model.id // empty')
COMPACT_WINDOW=200000
used=$(echo "$input" | jq -r "
  (.context_window.used_percentage // 0) as \$pct |
  (.context_window.context_window_size // 1) as \$total |
  (\$pct * \$total / 100 / $COMPACT_WINDOW * 100) | floor | if . > 100 then 100 else . end
")

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

# Progress bar
progress_bar() {
  local pct=$1
  local width=10
  local filled=$((pct * width / 100))
  [ "$filled" -gt "$width" ] && filled=$width
  [ "$filled" -lt 0 ] && filled=0
  local empty=$((width - filled))
  local bar=""
  for ((i=0; i<filled; i++)); do bar+="="; done
  for ((i=0; i<empty; i++)); do bar+=" "; done
  printf "[%s] %s%%" "$bar" "$pct"
}

BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'
SEP=' • '

dir_name=$(basename "$cwd")

# Line 1: {blue:dir} on {red:branch}
line1="${BLUE}${dir_name}${RESET}"

if [ -n "$branch" ]; then
  line1="${line1} on ${RED}${branch}${RESET}"
fi

# Line 2: context progress bar • {green:model}
line2=""
if [ -n "$used" ]; then
  bar=$(progress_bar "$used")
  line2="${YELLOW}${bar}${RESET}"
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

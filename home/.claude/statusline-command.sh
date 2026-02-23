#!/usr/bin/env bash
input=$(cat)

cwd=$(echo "$input" | jq -r '.cwd // empty')
model_id=$(echo "$input" | jq -r '.model.id // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

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

# Build: {blue:dir} on {red:branch} • {green:model} • {yellow:bar}
parts="${BLUE}${dir_name}${RESET}"

if [ -n "$branch" ]; then
  parts="${parts} on ${RED}${branch}${RESET}"
fi

if [ -n "$model" ]; then
  parts="${parts}${SEP}${GREEN}${model}${RESET}"
fi

if [ -n "$used" ]; then
  bar=$(progress_bar "$used")
  parts="${parts}${SEP}${YELLOW}${bar}${RESET}"
fi

printf "%b" "$parts"

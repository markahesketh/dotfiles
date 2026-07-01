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

# GitHub CI status for the current branch, read from a cache that a background
# job refreshes at most every 30s — the statusline never blocks on gh itself.
ci_token=""
if [ -n "$cwd" ] && [ -n "$branch" ]; then
  cache_dir="$HOME/.cache/claude-statusline"
  mkdir -p "$cache_dir"
  cache="$cache_dir/ci-$(printf '%s@%s' "$cwd" "$branch" | shasum | cut -c1-12)"
  now=$(date +%s)
  mtime=0
  [ -f "$cache" ] && mtime=$(stat -f %m "$cache" 2>/dev/null || echo 0)
  if [ $((now - mtime)) -ge 30 ]; then
    touch "$cache"  # claim the refresh slot; touch preserves any last-known value
    ( bash "$HOME/.claude/ci-status.sh" "$cwd" "$cache" ) >/dev/null 2>&1 &
  fi
  [ -f "$cache" ] && ci_token=$(cat "$cache" 2>/dev/null)
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

# CI segment: green tick when passing, yellow when running, red with the
# failure count when checks are failing; nothing when there's no PR/checks.
ci=""
case "$ci_token" in
  pass)      ci="${GREEN}✓ CI${RESET}" ;;
  pending:*) ci="${YELLOW}● CI ${ci_token#pending:}${RESET}" ;;
  fail:*)    ci="${RED}✗ CI ${ci_token#fail:}${RESET}" ;;
esac

# Line 2: {yellow:pct% • tokens} • {green:model} • {ci}
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

if [ -n "$ci" ]; then
  if [ -n "$line2" ]; then
    line2="${line2}${SEP}${ci}"
  else
    line2="$ci"
  fi
fi

if [ -n "$line2" ]; then
  printf "%b\n%b" "$line1" "$line2"
else
  printf "%b" "$line1"
fi

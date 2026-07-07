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

# Cache warmth: how long until this conversation's prompt cache goes cold.
# Prompt caching is a sliding window refreshed on every access, so the metric
# is "time since last message" vs the cache TTL. The TTL (5m or 1h) is read
# per-session from the last turn's usage.cache_creation breakdown, so it is
# accurate regardless of subscription/API/overage billing.
cache=""
tp=$(echo "$input" | jq -r '.transcript_path // empty')
if [ -n "$tp" ] && [ -f "$tp" ]; then
  info=$(tail -n 40 "$tp" | jq -rs '
    (map(select(.timestamp)) | last | .timestamp | sub("\\.[0-9]+Z$";"Z") | fromdateiso8601) as $last
    | (now - $last) as $elapsed
    | ([ .[]
         | select(.type=="assistant")
         | (.message.usage.cache_creation // {})
         | if   (.ephemeral_1h_input_tokens // 0) > 0 then "1h"
           elif (.ephemeral_5m_input_tokens // 0) > 0 then "5m"
           else empty end ] | last // "") as $ttl
    | "\($ttl) \($elapsed | floor)"' 2>/dev/null)
  ttl=${info%% *}
  elapsed=${info##* }
  case "$ttl" in
    1h) win=3600 ;;
    5m) win=300 ;;
    *)  win=0 ;;
  esac
  case "$elapsed" in
    ''|*[!0-9]*) win=0 ;;
  esac
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

# Cache segment: green when comfortably warm, yellow in the last 2 min, red
# when cold. Empty on a brand-new session (no cache-creation record yet).
cache_seg=""
if [ "${win:-0}" -gt 0 ]; then
  remaining=$((win - elapsed))
  if [ "$remaining" -le 0 ]; then
    cache_seg="${RED}cache cold${RESET}"
  else
    if [ "$remaining" -ge 60 ]; then
      label="$(( (remaining + 59) / 60 ))m left"
    else
      label="${remaining}s left"
    fi
    if [ "$remaining" -le 120 ]; then
      cache_seg="${YELLOW}cache ${label}${RESET}"
    else
      cache_seg="${GREEN}cache ${label}${RESET}"
    fi
  fi
fi

# Line 2: {yellow:pct% • tokens} • {cache} • {green:model} • {ci}
line2=""
if [ -n "$used" ]; then
  if [ "$used" -gt 100 ]; then
    color="$RED_BG"
  else
    color="$YELLOW"
  fi
  line2="${color}${tokens} (${used}%)${RESET}"
fi

if [ -n "$cache_seg" ]; then
  if [ -n "$line2" ]; then
    line2="${line2}${SEP}${cache_seg}"
  else
    line2="$cache_seg"
  fi
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

#!/usr/bin/env bash
# Set the current tmux pane title from the first user prompt submitted to an
# agent session. SessionStart hooks clear the per-pane marker so each new
# session can retitle the pane.

[ -n "$TMUX_PANE" ] || exit 0

if [ "${1:-}" = "--reset" ]; then
    tmux set -p -u -t "$TMUX_PANE" @agent_initial_prompt_titled 2>/dev/null || true
    tmux set -p -u -t "$TMUX_PANE" @agent_pane_title 2>/dev/null || true
    tmux refresh-client 2>/dev/null || true
    exit 0
fi

if [ "$(tmux show -p -v -t "$TMUX_PANE" @agent_initial_prompt_titled 2>/dev/null)" = "1" ]; then
    exit 0
fi

title=$(
    python3 -c '
import json
import re
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(1)

prompt = ""
for key in ("prompt", "user_prompt", "message"):
    value = data.get(key)
    if isinstance(value, str):
        prompt = value
        break

if not prompt:
    tool_input = data.get("tool_input")
    if isinstance(tool_input, dict):
        for key in ("prompt", "user_prompt", "message"):
            value = tool_input.get(key)
            if isinstance(value, str):
                prompt = value
                break

prompt = re.sub(r"\s+", " ", prompt).strip()
if not prompt:
    sys.exit(1)

if len(prompt) > 60:
    prompt = prompt[:57].rstrip() + "..."

print(prompt)
'
)

[ -n "$title" ] || exit 0

tmux select-pane -t "$TMUX_PANE" -T "$title" 2>/dev/null || true
tmux set -p -t "$TMUX_PANE" @agent_pane_title "$title" 2>/dev/null || true
tmux set -p -t "$TMUX_PANE" @agent_initial_prompt_titled 1 2>/dev/null || true
tmux refresh-client 2>/dev/null || true

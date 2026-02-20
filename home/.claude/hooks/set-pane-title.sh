#!/bin/sh
# Sets the tmux pane title to a truncated version of the first user prompt.
# Runs on every UserPromptSubmit, but does nothing after the first prompt.
[ -z "$TMUX_PANE" ] && exit 0

flag="/tmp/claude-pane-titled-${TMUX_PANE#%}"
[ -f "$flag" ] && exit 0

prompt=$(python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    p = d.get('prompt', '')[:40].replace('\n', ' ').strip()
    print(p)
except:
    pass
")

[ -n "$prompt" ] && tmux select-pane -T "$prompt"
touch "$flag"

#!/usr/bin/env bash
# Flag the current tmux pane to draw attention by setting the @agent_flag pane
# option, which pane-border-style in ~/.tmux.conf reads to colour the border.
# Shared by Claude and Codex notify hooks.
#   pane-flag.sh red      # colour this pane's border
#   pane-flag.sh clear    # remove the colour
[ -n "$TMUX_PANE" ] || exit 0

if [ "${1:-clear}" = "clear" ]; then
    tmux set -p -u -t "$TMUX_PANE" @agent_flag 2>/dev/null
else
    tmux set -p -t "$TMUX_PANE" @agent_flag "$1" 2>/dev/null
fi

tmux refresh-client 2>/dev/null || true

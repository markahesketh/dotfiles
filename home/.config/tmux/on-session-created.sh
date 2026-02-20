#!/bin/bash
path="$1"
session_name="$2"

# Rename session if it was auto-generated (tmux uses numeric names by default)
if [[ "$session_name" =~ ^[0-9]+$ ]]; then
    tmux rename-session -t "$session_name" "$(basename "$path")"
fi

# Rename window to git default branch
branch=$(git -C "$path" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|.*/||')
tmux rename-window "${branch:-main}"

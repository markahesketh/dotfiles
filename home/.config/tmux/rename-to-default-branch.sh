#!/bin/bash
branch=$(git -C "$1" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|.*/||')
tmux rename-window "${branch:-main}"

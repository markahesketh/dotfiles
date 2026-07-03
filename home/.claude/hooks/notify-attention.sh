#!/usr/bin/env bash
# Hook: fires on Claude Notification event (permission prompts, elicitation dialogs).
# Receives JSON on stdin.

input=$(cat)

# Get repo name from git in the current working directory
repo=$(git rev-parse --show-toplevel 2>/dev/null | xargs basename 2>/dev/null || basename "$PWD")

# Extract message from hook input if available
hook_message=$(printf '%s' "$input" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('message', ''))
except Exception:
    print('')
" 2>/dev/null || true)

title="Claude: ${repo:-unknown}"
message="${hook_message:-Requires attention}"

if printf '%s' "$message" | grep -Eiq '(^|[^a-z])(allowed|approved|auto-approv|pre-?approved)([^a-z]|$)'; then
    exit 0
fi

# Desktop notification
osascript \
    -e 'on run argv' \
    -e 'display notification (item 2 of argv) with title (item 1 of argv)' \
    -e 'end run' \
    -- "$title" "$message"

# Play sound
afplay ~/.glm/media/notification.mp3 &

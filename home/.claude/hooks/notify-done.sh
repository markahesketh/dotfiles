#!/usr/bin/env bash
# Hook: fires on Claude Stop event, sends a macOS desktop notification.
# Receives JSON on stdin with session_id and transcript_path.

input=$(cat)

# Get repo name from git in the current working directory
repo=$(git rev-parse --show-toplevel 2>/dev/null | xargs basename 2>/dev/null || basename "$PWD")

# Extract transcript path from hook input
transcript_path=$(printf '%s' "$input" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('transcript_path', ''))
except Exception:
    print('')
" 2>/dev/null || true)

# Read the first user message from the transcript as context
context=""
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
    context=$(python3 - "$transcript_path" <<'EOF'
import sys, json
try:
    with open(sys.argv[1]) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                msg = json.loads(line)
                if msg.get('role') == 'user':
                    content = msg.get('content', '')
                    if isinstance(content, str):
                        text = content.strip()
                    elif isinstance(content, list):
                        text = next(
                            (b.get('text', '').strip()
                             for b in content
                             if isinstance(b, dict) and b.get('type') == 'text'),
                            ''
                        )
                    else:
                        text = ''
                    if text:
                        print(text[:120])
                        break
            except Exception:
                continue
except Exception:
    pass
EOF
    2>/dev/null || true)
fi

title="Claude: ${repo:-unknown}"
message="${context:-Task complete}"

# Send macOS notification — argv style avoids shell quoting issues
osascript \
    -e 'on run argv' \
    -e 'display notification (item 2 of argv) with title (item 1 of argv)' \
    -e 'end run' \
    -- "$title" "$message"

# Play sound
afplay ~/.claude/media/done.mp3 &

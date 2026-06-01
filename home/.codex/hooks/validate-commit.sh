#!/usr/bin/env bash
# Codex only matches PreToolUse hooks by tool name, so this wrapper keeps the
# commit validator from running for unrelated Bash commands.

input=$(cat)

if ! printf '%s' "$input" | python3 -c '
import json
import re
import sys

try:
    command = json.load(sys.stdin).get("tool_input", {}).get("command", "")
except Exception:
    sys.exit(1)

sys.exit(0 if re.search(r"(^|[;&|()\s])git\s+commit\b", command) else 1)
'; then
    exit 0
fi

printf '%s' "$input" | bash ~/.claude/hooks/validate-commit.sh

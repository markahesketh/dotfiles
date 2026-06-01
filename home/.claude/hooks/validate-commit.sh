#!/usr/bin/env bash
# PreToolUse hook, gated by "if": "Bash(git commit *)" in settings.json, so it
# only runs on commit creation. Denies commits whose subject breaks the
# create-commits conventions and feeds the reason back to Claude so it can
# rewrite and retry. Lenient: only clear mechanical violations are denied.
# Reads PreToolUse JSON on stdin; emits a permissionDecision on stdout
# (deny to block, silent exit 0 to fall through to normal permission flow).

python3 -c '
import sys, json, re

cmd = json.load(sys.stdin).get("tool_input", {}).get("command", "")

# Skip history rewrites and editor/-F commits (no readable subject).
if re.search(r"--(amend|fixup|squash|no-edit)\b", cmd) or not re.search(r"-m\b|--message\b", cmd):
    sys.exit(0)

# Subject = first line of a heredoc body or a quoted -m message.
m = (re.search(r"<<-?\s*[\"\x27]?(\w+)[\"\x27]?\s*\n(.*?)\n\s*\1", cmd, re.S)
     or re.search(r"(?:-m|--message)\s+(\"|\x27)(.*?)\1", cmd, re.S))
subject = m.group(2).strip().splitlines()[0].strip() if m and m.group(2).strip() else ""
if not subject or re.match(r"(Merge|Revert)\b", subject):
    sys.exit(0)

# Conventional subject (no scope) with no trailing period. A scoped subject like
# "feat(api): x" fails the type match, so this covers scopes too.
types = "feat|fix|docs|style|refactor|perf|test|chore"
if re.match(rf"^({types})(!)?: .+", subject) and not subject.endswith("."):
    sys.exit(0)

print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "This commit does not follow the create-commits conventions. Invoke the create-commits skill to rewrite the message, then commit again.",
}}))
'

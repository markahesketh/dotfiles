#!/usr/bin/env bash
# PreToolUse hook, gated by "if": "Bash(git commit *)" in settings.json, so it
# only runs on commit creation. Blocks messages that break the create-commits
# conventions so they get rewritten. Lenient: only clear mechanical violations.
# Reads PreToolUse JSON on stdin. exit 2 + stderr = block; exit 0 = allow.

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

types = "feat|fix|docs|style|refactor|perf|test|chore"
# Conventional subject (no scope) and no trailing period. A scoped subject like
# "feat(api): x" fails the type match, so this covers scopes too.
if re.match(rf"^({types})(!)?: .+", subject) and not subject.endswith("."):
    sys.exit(0)

print("Commit message does not follow the create-commits conventions:",
      "  " + subject,
      "Invoke the create-commits skill to rewrite it, then commit again.",
      sep="\n", file=sys.stderr)
sys.exit(2)
'

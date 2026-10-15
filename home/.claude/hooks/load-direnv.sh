#!/usr/bin/env bash
# SessionStart: load the project's .envrc into the Bash tool, whose shell never
# draws a prompt and so never runs direnv's hook.
[[ -n "${CLAUDE_ENV_FILE:-}" ]] && command -v direnv >/dev/null || exit 0
direnv export bash 2>/dev/null >>"$CLAUDE_ENV_FILE"
exit 0

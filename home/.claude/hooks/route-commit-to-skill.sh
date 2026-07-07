#!/usr/bin/env bash
# PreToolUse(Bash): route direct commit creation through the `commit` skill.
#
# Opus reaches for `git commit` itself and won't organically invoke the commit
# skill (measured: 0% trigger rate across every description variant), so no
# wording fixes this — the routing has to be deterministic. We deny a direct
# `git commit` and tell the model to use the skill instead.
#
# The skill creates commits via `bash scripts/commit.sh` (git commit lives
# inside that script, not in the tool command string), so its own commits are
# never matched here. Amend/rewrite is exempt — that's not commit creation and
# the skill deliberately doesn't own it.

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')

# Strip an rtk/rtk-proxy prefix so `rtk git commit ...` is caught too.
norm=$cmd
norm=${norm#rtk proxy }
norm=${norm#rtk }

if printf '%s' "$norm" | grep -qE '\bgit[[:space:]]+commit\b'; then
  if printf '%s' "$norm" | grep -qE '\bgit[[:space:]]+commit\b.*--amend'; then
    exit 0
  fi
  cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Do not run `git commit` directly. Invoke the commit skill instead (Skill tool, skill name: commit). It inspects the worktree, groups changes by intention into atomic commits, stages selectively, and writes validated Conventional Commit messages. The skill creates commits through its own scripts/commit.sh, which this hook allows — so route through it rather than committing by hand. (Amending/rewriting existing history is exempt and not what this skill is for.)"}}}
JSON
  exit 0
fi
exit 0

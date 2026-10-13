#!/usr/bin/env bash
# PreToolUse(Bash), shared by Claude Code and Codex: route commit and PR
# creation through the `commit` and `pr` skills.
#
# The skill descriptions do the real routing; this is the fallback for when the
# model reaches for `git commit` / `gh pr create` itself. The skills' own
# scripts (commit.sh, create.sh) run these inside a script, so the Bash command
# the hook sees never matches and the skills pass straight through.
#
# Blocks with exit 2 + stderr: both harnesses treat that as a deny and show the
# reason to the model, with no JSON payload to get wrong.

cmd=$(jq -r '.tool_input.command // ""' 2>/dev/null)

# Match only in command position: start of a line or after ; & | ( — so
# `echo "git commit"` or `grep "gh pr create"` pass. Allows an rtk / rtk proxy
# prefix, env assignments, and global flags (git -C dir, gh -R repo).
pre='(^|[;&|(])[[:space:]]*(rtk[[:space:]]+(proxy[[:space:]]+)?)?([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*'
git_commit="${pre}git([[:space:]]+-[cC][[:space:]]+[^[:space:]]+)*[[:space:]]+commit([[:space:]]|$)"
gh_pr_create="${pre}gh([[:space:]]+(-R|--repo)[[:space:]]+[^[:space:]]+)*[[:space:]]+pr[[:space:]]+create([[:space:]]|$)"

commit_line=$(printf '%s\n' "$cmd" | grep -E "$git_commit")
if [ -n "$commit_line" ] && ! printf '%s' "$commit_line" | grep -q -- '--amend'; then
  echo 'Do not run `git commit` directly. Invoke the commit skill (skill name: commit) and commit through its scripts/commit.sh. Amending is exempt.' >&2
  exit 2
fi

if printf '%s\n' "$cmd" | grep -qE "$gh_pr_create"; then
  echo 'Do not run `gh pr create` directly. Invoke the pr skill (skill name: pr) and open the PR through its scripts/create.sh.' >&2
  exit 2
fi

exit 0

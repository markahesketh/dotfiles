#!/usr/bin/env bash
# Read-only snapshot of the worktree for deciding how to group commits.
#
# One call replaces the scattered git status/diff invocations. Unlike `git diff`
# alone it also surfaces UNTRACKED files (new files show in no diff) and their
# content, so nothing is silently missed when grouping.
#
# The FULL DIFF sections are valid patch text: to split one file's hunks across
# commits, copy the file's `diff --git`/`---`/`+++` header plus the hunks you
# want into a .patch file and hand it to commit.sh --patch.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

section() { printf '\n===== %s =====\n' "$1"; }

section "BRANCH"
git rev-parse --abbrev-ref HEAD

section "STATUS (porcelain: XY path)"
git status --porcelain=v1

section "STAGED (name-status)"
git diff --cached --name-status

section "UNSTAGED, tracked (name-status)"
git diff --name-status

section "UNTRACKED (new files)"
git ls-files --others --exclude-standard

section "DIFFSTAT"
if git rev-parse --verify -q HEAD >/dev/null; then
  git --no-pager diff HEAD --stat
else
  echo "(no commits yet)"
  git --no-pager diff --cached --stat
fi

section "FULL DIFF — staged"
git --no-pager diff --cached

section "FULL DIFF — unstaged, tracked"
git --no-pager diff

section "FULL DIFF — untracked (vs empty)"
while IFS= read -r f; do
  [ -n "$f" ] || continue
  git --no-pager diff --no-index -- /dev/null "$f" || true
done < <(git ls-files --others --exclude-standard)

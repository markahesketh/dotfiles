#!/usr/bin/env bash
# Read-only snapshot of everything needed to draft a PR briefing.
#
# One call replaces the scattered git/gh invocations: base branch, current
# branch, the commits and diff the reviewer will see, and any uncommitted file
# that will be LEFT BEHIND by the PR (this skill commits nothing).
#
# Optional argument: an explicit base branch, for a stacked branch or a
# repository that releases from something other than its default branch.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

section() { printf '\n===== %s =====\n' "$1"; }

base="${1:-}"
if [ -z "$base" ]; then
  base="$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || true)"
fi
if [ -z "$base" ]; then
  base="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)"
fi
if [ -z "$base" ]; then
  echo "Could not resolve a base branch. Pass one as the first argument." >&2
  exit 1
fi

section "BASE BRANCH"
echo "$base"

section "CURRENT BRANCH"
git rev-parse --abbrev-ref HEAD

section "UNCOMMITTED (left behind by this PR)"
git status --porcelain=v1
git ls-files --others --exclude-standard

if ! git rev-parse --verify -q "$base" >/dev/null && \
   ! git rev-parse --verify -q "origin/$base" >/dev/null; then
  echo "Base '$base' is not a known ref locally. Run: git fetch origin $base" >&2
  exit 1
fi
ref="$base"
git rev-parse --verify -q "$ref" >/dev/null || ref="origin/$base"

section "COMMITS vs $ref"
git --no-pager log --oneline "$ref..HEAD"

section "DIFFSTAT vs $ref"
git --no-pager diff --stat "$ref...HEAD"

section "FULL DIFF vs $ref"
git --no-pager diff "$ref...HEAD"

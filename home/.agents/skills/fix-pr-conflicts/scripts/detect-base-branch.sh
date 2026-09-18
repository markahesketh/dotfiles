#!/usr/bin/env bash
# Resolve the repo's base branch so the skill has a rebase target without guessing.
#
# Optional argument: an explicit base branch, for a stacked branch.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

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

echo "$base"

#!/usr/bin/env bash
#
# resolve-scope.sh — resolve what the `land` pipeline should review.
#
# `land` runs this once, then passes the decision into each stage (review-tests,
# finalise, simplify, react-best-practices) as an argument, so every stage reviews
# one coherent set of changes. The stages themselves never call this — they just
# consume the scope they're handed. (Lint is the deliberate exception — it always
# runs on the whole tree and is never scoped.)
#
# Usage:   resolve-scope.sh [BASE]
#   BASE   optional explicit base branch/ref. Forces branch mode against it and
#          skips parent-branch detection. e.g. `resolve-scope.sh staging`.
#
# Emits key=value lines on stdout. Consumers read these; they don't re-derive scope.
#   mode=uncommitted|branch|ambiguous|empty
#   range=<rev range>     the argument to `git diff` (e.g. `HEAD` or `origin/staging...HEAD`)
#   base=<ref>            resolved base ref, in branch mode
#   candidates=<a,b>      the tied bases, in ambiguous mode (parent can't be inferred)
#   untracked=<f1,f2>     untracked files (uncommitted mode only; absent from the diff)
#   react=true|false      does the scoped diff touch React (.tsx/.jsx or a react import)?
#
# Modes:
#   uncommitted  work in progress in the tree — review `git diff HEAD` + untracked files
#   branch       clean tree — review this branch's own changes: `git diff BASE...HEAD`
#                (three dots = merge-base..HEAD, so a base that moved on doesn't matter)
#   ambiguous    clean tree, two candidate parents tie — caller must ask which base to use
#   empty        clean tree, branch adds nothing over any candidate base — nothing to review

emit() { printf '%s=%s\n' "$1" "$2"; }

resolve_ref() {
  local c="$1" r=""
  git show-ref -q --verify "refs/remotes/origin/$c" && r="origin/$c"
  [ -z "$r" ] && git show-ref -q --verify "refs/heads/$c" && r="$c"
  [ -z "$r" ] && git rev-parse -q --verify "$c" >/dev/null 2>&1 && r="$c"
  printf '%s' "$r"
}

# React heuristic: added .tsx/.jsx files, or added lines importing react.
react_for_range() {
  local range="$1"
  git diff --name-only "$range" 2>/dev/null | grep -qE '\.(tsx|jsx)$' && { echo true; return; }
  git diff "$range" 2>/dev/null \
    | grep -qE "^\+.*(from ['\"]react|require\(['\"]react|import ['\"]react)" && { echo true; return; }
  echo false
}

explicit="${1:-}"

if [ -n "$explicit" ]; then
  base=$(resolve_ref "$explicit")
  if [ -z "$base" ]; then
    emit mode empty
    emit note "explicit base '$explicit' not found"
    exit 0
  fi
  range="$base...HEAD"
  emit mode branch
  emit base "$base"
  emit range "$range"
  emit react "$(react_for_range "$range")"
  exit 0
fi

if [ -n "$(git status --porcelain)" ]; then
  emit mode uncommitted
  emit range HEAD
  untracked=$(git ls-files --others --exclude-standard | paste -sd, -)
  [ -n "$untracked" ] && emit untracked "$untracked"
  emit react "$(react_for_range HEAD)"
  exit 0
fi

# Clean tree: infer the parent branch — the candidate whose fork point is closest to HEAD.
cur=$(git rev-parse --abbrev-ref HEAD)
default=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null)
[ -z "$default" ] && default=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')

best=""; best_fork=""; best_n=""; tie=""
for c in "$default" staging develop main master; do
  { [ -z "$c" ] || [ "$c" = "$cur" ]; } && continue
  ref=$(resolve_ref "$c")
  [ -z "$ref" ] && continue
  fork=$(git merge-base HEAD "$ref" 2>/dev/null) || continue
  n=$(git rev-list --count "$fork"..HEAD 2>/dev/null)
  { [ -z "$n" ] || [ "$n" -eq 0 ]; } && continue   # base at/ahead of HEAD — adds nothing
  if [ -z "$best_n" ] || [ "$n" -lt "$best_n" ]; then
    best_n=$n; best=$ref; best_fork=$fork; tie=""
  elif [ "$n" -eq "$best_n" ] && [ "$fork" != "$best_fork" ]; then
    tie="$best,$ref"
  fi
done

if [ -n "$tie" ]; then
  emit mode ambiguous
  emit candidates "$tie"
elif [ -z "$best" ]; then
  emit mode empty
else
  range="$best...HEAD"
  emit mode branch
  emit base "$best"
  emit range "$range"
  emit react "$(react_for_range "$range")"
fi

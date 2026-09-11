#!/usr/bin/env bash
# Push the current branch and open the PR. Draft unless --ready is given.
#
# Usage:
#   create.sh --base <branch> --title <title> --body-file <path> [--ready]
#
# Prints the PR URL on the last line. Re-running against a branch that already
# has a PR prints that PR's URL instead of failing, so the step is safe to retry.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

base=""; title=""; body_file=""; draft="--draft"
while [ $# -gt 0 ]; do
  case "$1" in
    --base)      base="$2"; shift 2 ;;
    --title)     title="$2"; shift 2 ;;
    --body-file) body_file="$2"; shift 2 ;;
    --ready)     draft=""; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

for pair in "base:--base" "title:--title" "body_file:--body-file"; do
  name="${pair%%:*}"
  if [ -z "${!name}" ]; then echo "Missing ${pair##*:}" >&2; exit 2; fi
done
if [ ! -f "$body_file" ]; then echo "No such body file: $body_file" >&2; exit 2; fi

git push -u origin HEAD

existing="$(gh pr view --json url -q .url 2>/dev/null || true)"
if [ -n "$existing" ]; then
  echo "A PR already exists for this branch; pushed to it."
  echo "$existing"
  exit 0
fi

gh pr create ${draft:+$draft} \
  --base "$base" \
  --title "$title" \
  --body-file "$body_file"

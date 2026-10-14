#!/usr/bin/env bash
# Push the current branch and open the PR. Draft unless --ready is given.
#
# Usage:
#   create.sh --base <branch> --title <title> --body-file <path> [--ready]
#             [--attach </abs/path/to/media>[#alt text]]...
#
# Each --attach uploads an image or video (gh >= 2.99). A body reference to the
# same absolute path, e.g. ![alt](/tmp/pr/after.png), is rewritten to the
# uploaded URL; unreferenced files are appended. Paths must be absolute because
# the script runs from the repository root.
#
# Prints the PR URL on the last line. Re-running against a branch that already
# has a PR prints that PR's URL instead of failing, so the step is safe to retry.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

base=""; title=""; body_file=""; draft="--draft"; attach=()
while [ $# -gt 0 ]; do
  case "$1" in
    --base)      base="$2"; shift 2 ;;
    --title)     title="$2"; shift 2 ;;
    --body-file) body_file="$2"; shift 2 ;;
    --ready)     draft=""; shift ;;
    --attach)    attach+=(--attach "$2"); shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

for pair in "base:--base" "title:--title" "body_file:--body-file"; do
  name="${pair%%:*}"
  if [ -z "${!name}" ]; then echo "Missing ${pair##*:}" >&2; exit 2; fi
done
if [ ! -f "$body_file" ]; then echo "No such body file: $body_file" >&2; exit 2; fi
for ((i = 1; i < ${#attach[@]}; i += 2)); do
  file="${attach[i]%%#*}"
  case "$file" in /*) ;; *) echo "Attachment path must be absolute: $file" >&2; exit 2 ;; esac
  if [ ! -f "$file" ]; then echo "No such attachment: $file" >&2; exit 2; fi
done

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
  --body-file "$body_file" \
  ${attach[@]+"${attach[@]}"}

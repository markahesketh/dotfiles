#!/bin/sh
# UserPromptSubmit hook: renames the current branch from t3code/* to
# markahesketh/*, without racing T3 Code's own async rename from
# t3code/<hash-or-uuid> to t3code/<generated-slug> (see
# isTemporaryWorktreeBranch / ProviderCommandReactor.ts upstream). Retries a
# bounded number of times per session so it waits for that slug instead of
# permanently locking in the placeholder hash, but still stops eventually
# so it isn't running on every single turn.
set -eu

MAX_ATTEMPTS=8
TEMP_BRANCH_PATTERN='^t3code/([0-9a-f]{8}|[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12})$'

input="$(cat 2>/dev/null || true)"
session_id="$(printf '%s' "$input" | jq -r '.session_id // "unknown"' 2>/dev/null || echo unknown)"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"
[ -n "$cwd" ] || cwd="$PWD"

repo="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)" || exit 0

state_root="${TMPDIR:-/tmp}/rename-t3code-branch"
state_key="$(printf '%s\0%s' "$session_id" "$repo" | git hash-object --stdin)"
state_dir="$state_root/$state_key"
done_marker="$state_dir/done"
attempts_file="$state_dir/attempts"

[ -f "$done_marker" ] && exit 0
mkdir -p "$state_dir"

branch="$(git -C "$repo" symbolic-ref --short -q HEAD || true)"

case "$branch" in
  t3code/*) ;;
  *)
    : > "$done_marker"
    exit 0
    ;;
esac

if printf '%s' "$branch" | grep -qE "$TEMP_BRANCH_PATTERN"; then
  attempts="$(cat "$attempts_file" 2>/dev/null || echo 0)"
  case $attempts in '' | *[!0-9]*) attempts=0 ;; esac
  attempts=$((attempts + 1))
  if [ "$attempts" -ge "$MAX_ATTEMPTS" ]; then
    : > "$done_marker"
  else
    printf '%s\n' "$attempts" > "$attempts_file"
  fi
  exit 0
fi

suffix="${branch#t3code/}"
new_branch="markahesketh/$suffix"

if git -C "$repo" show-ref --verify --quiet "refs/heads/$new_branch"; then
  : > "$done_marker"
  echo "{\"systemMessage\": \"Branch '$branch' not renamed: '$new_branch' already exists.\"}"
  exit 0
fi

if git -C "$repo" branch -m "$branch" "$new_branch" 2>/dev/null; then
  : > "$done_marker"
  echo "{\"systemMessage\": \"Renamed branch '$branch' to '$new_branch'.\"}"
fi

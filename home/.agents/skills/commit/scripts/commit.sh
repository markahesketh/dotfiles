#!/usr/bin/env bash
# Compose ONE commit from whole files and/or specific hunks, then commit it.
#
# Usage:
#   commit.sh <message-file> [<pathspec>...] [--patch <patch-file>]...
#
#   <pathspec>       whole file(s) to stage (git add -- <pathspec>).
#   --patch <file>   a patch holding only the hunks you want, applied to the
#                    index with `git apply --cached`, so different hunks of the
#                    same file can land in different commits. Repeatable. Slice
#                    the hunks out of inspect.sh's FULL DIFF, keeping each file's
#                    `diff --git`/`---`/`+++` header plus the chosen `@@` hunks.
#
# Why a message FILE, not `-m`: quotes, `$`, `!`, backticks and newlines in a
# message are mangled by the shell with `git commit -m "..."`. Reading the
# message from a file removes that entire class of failure.
#
# Why explicit pathspecs/patches: staging is limited to exactly what you pass,
# so it is structurally impossible to `git add .` a whole dirty tree when
# splitting it into intention-scoped commits.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

msg_file="${1:-}"
if [ -z "$msg_file" ]; then
  echo "usage: commit.sh <message-file> [<pathspec>...] [--patch <patch-file>]..." >&2
  exit 2
fi
shift

paths=()
patches=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --patch)
      shift
      [ "$#" -ge 1 ] || { echo "error: --patch needs a file argument" >&2; exit 2; }
      patches+=("$1")
      ;;
    *)
      paths+=("$1")
      ;;
  esac
  shift
done

if [ "${#paths[@]}" -eq 0 ] && [ "${#patches[@]}" -eq 0 ]; then
  echo "error: give at least one pathspec or --patch file (never commit a whole dirty tree blindly)" >&2
  exit 2
fi
if [ ! -s "$msg_file" ]; then
  echo "error: message file is missing or empty: $msg_file" >&2
  exit 2
fi

# Enforce the skill's own rule mechanically: scope-less Conventional Commit
# subject, known type, optional ! for a breaking change.
subject="$(head -n1 -- "$msg_file")"
types='feat|fix|docs|style|refactor|perf|test|chore'
if ! printf '%s' "$subject" | grep -qE "^($types)!?: .+"; then
  echo "error: subject must be '<type>: <description>' (no scope)." >&2
  echo "       type in {$types}; add '!' for a breaking change (e.g. 'feat!: ...')." >&2
  echo "  got: $subject" >&2
  exit 1
fi

if [ "${#paths[@]}" -gt 0 ]; then
  git add -- "${paths[@]}"
fi
if [ "${#patches[@]}" -gt 0 ]; then
  for p in "${patches[@]}"; do
    [ -s "$p" ] || { echo "error: patch file missing or empty: $p" >&2; exit 1; }
    # A zero-context patch (git diff -U0, needed to separate hunks that sit only
    # a line or two apart) has no ' '-prefixed context lines and must be applied
    # by position. Context patches keep git's context safety check.
    zero=""
    grep -qE '^ ' "$p" || zero="--unidiff-zero"
    if ! git apply --cached --recount $zero "$p"; then
      echo "error: could not apply $p to the index. Rerun inspect.sh and reslice —" >&2
      echo "       hunk line numbers go stale after an earlier commit touches the file." >&2
      exit 1
    fi
  done
fi

if git diff --cached --quiet; then
  echo "error: nothing was staged — check your pathspecs/patches against the inspect output" >&2
  exit 1
fi

git commit -F "$msg_file"
git --no-pager log -1 --oneline --stat

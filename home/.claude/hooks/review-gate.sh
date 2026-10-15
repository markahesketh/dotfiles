#!/usr/bin/env bash
# Tracks which code /deslop and /no-comments have reviewed, so route-to-skill.sh
# can block a commit or push that adds lines the skill has not seen.
#
#   review-gate.sh mark <skill>                  record the working tree as reviewed
#   review-gate.sh check <skill> worktree|HEAD   exit 1 with the rerun scope on stderr
#                                                when that tree adds unreviewed lines
#
# Comparing trees rather than timestamps makes a rerun on unchanged code a no-op
# and scopes a stale rerun to exactly the lines added since.
set -euo pipefail

mode=$1 skill=$2 target=${3:-worktree}
git rev-parse --git-dir >/dev/null 2>&1 || exit 0
state=$(git rev-parse --git-path claude-review)

# A temporary index captures untracked files without touching the real index.
worktree_tree() {
  local tmp; tmp=$(mktemp -d)
  cp "$(git rev-parse --git-path index)" "$tmp/index" 2>/dev/null || true
  GIT_INDEX_FILE=$tmp/index git add -A
  GIT_INDEX_FILE=$tmp/index git write-tree
  rm -rf "$tmp"
}

case $mode in
  mark)
    mkdir -p "$state"
    worktree_tree >"$state/$skill"
    echo "Recorded the working tree as reviewed by $skill."
    ;;
  check)
    if [ "$target" = HEAD ]; then
      current=$(git rev-parse 'HEAD^{tree}')
    else
      current=$(worktree_tree)
    fi
    reviewed=$(cat "$state/$skill" 2>/dev/null || true)
    # gc prunes old snapshot trees; a missing one means a full review.
    if [ -n "$reviewed" ] && git cat-file -e "$reviewed" 2>/dev/null; then
      added=$(git diff --numstat "$reviewed" "$current" | awk '$1 != "-" { n += $1 } END { print n + 0 }')
      [ "$added" -eq 0 ] && exit 0
      scope="the $added lines added since its last run: \`git diff $reviewed $current\`"
    else
      scope="the branch diff against its base, including uncommitted changes"
    fi
    followup="retry"
    [ "$target" = HEAD ] && followup="commit its edits, then retry"
    echo "Run the $skill skill (pstack:$skill) on $scope. Then run \`bash ~/.claude/hooks/review-gate.sh mark $skill\` and $followup." >&2
    exit 1
    ;;
esac

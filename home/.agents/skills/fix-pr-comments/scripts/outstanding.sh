#!/usr/bin/env bash
# Prints a PR's review feedback as compact JSON lines: unresolved threads, non-empty review bodies, PR comments.
set -euo pipefail
pr=${1:?usage: outstanding.sh <pr>}
repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
trim='gsub("(?s)<!--.*?-->"; "") | .[0:1500]'

gh api graphql --paginate -F owner="${repo%/*}" -F name="${repo#*/}" -F pr="$pr" -f query='
query($owner: String!, $name: String!, $pr: Int!, $endCursor: String) {
  repository(owner: $owner, name: $name) { pullRequest(number: $pr) {
    reviewThreads(first: 100, after: $endCursor) {
      pageInfo { hasNextPage endCursor }
      nodes { id isResolved isOutdated path line comments(first: 20) { nodes { author { login } body } } }
    } } } }' --jq ".data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved | not)
  | {thread: .id, at: \"\(.path):\(.line // \"outdated\")\", comments: [.comments.nodes[] | {by: .author.login, body: (.body | $trim)}]}"

gh api "repos/$repo/pulls/$pr/reviews" --paginate --jq ".[] | select(.body != \"\") | {review: .id, by: .user.login, state, body: (.body | $trim)}"
gh api "repos/$repo/issues/$pr/comments" --paginate --jq ".[] | {comment: .id, by: .user.login, body: (.body | $trim)}"

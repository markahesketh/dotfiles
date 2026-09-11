---
name: fix-merge-conflicts
description: Fix merge conflicts on PRs via rebase.
disable-model-invocation: true
---

Goal:
Resolve merge conflicts between this branch and `origin/{base_branch}` without regressing the intended behaviour.

Prerequisite:
1. Resolve the base branch: `bash <skill-dir>/scripts/detect-base-branch.sh`. Optional first argument is a specific base if the branch is stacked on another feature branch.

Steps:
1. Fetch the latest base branch: `git fetch origin {base_branch}`.
2. Rebase onto the base branch: `git rebase origin/{base_branch}`.
3. Inspect the conflicted files and the competing changes before editing.
4. Resolve every conflict carefully, preserving the intended final behaviour from both sides.
5. Run `git diff --check` and verify no conflict markers remain.

Done:
- There are no conflicted files left.
- `git diff --check` is clean and no conflict markers remain.

Reply:
Briefly summarise which files were resolved.
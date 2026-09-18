No. The stack is not good to go. The green mark on 6117 does not mean the tests passed. It means the tests did not run.

## Why 6117 is green

PR 6117 has an empty diff. `gh pr diff 6117` gives zero lines. Its head commit is the same content as its base branch (`markahesketh/adapt-correctness-tasks-filter`, PR 6225).

CI selects test jobs from the changed paths. With no changed paths, CI skipped all the test jobs:

- Test Ruby — SKIPPED
- Test Cucumber — SKIPPED
- Test JavaScript — SKIPPED
- Test Python — SKIPPED
- Test RLS provisioning — SKIPPED
- Lint — SKIPPED
- Test dv-cli and the code owner gate — SKIPPED

Only 8 checks passed. All 8 are meta checks: `check_pr_requirements`, `Check changed paths`, `Lint GitHub Actions`, the review-app build, the Meticulous build and the secret audit. `Check for build success` reports success because a skipped job is not a failed job.

Compare the totals. 6117 ran 19 checks. Every other PR in the stack ran 79 to 88 checks. That difference alone shows 6117 tested nothing.

## What is below it

Two PRs in the stack are red now:

- **PR 6114** (`adapt-task-parity`) — `Test Ruby (32, 34)` failed. One example: `spec/system/virtual_environment/item_analytics_spec.rb:190` — "Item Analytics with multiple location types the CSV includes the location type column". The failure is at `click_link_or_button group_name`. `Check for build success` failed.
- **PR 6116** (`adapt-obstruction-denominator`) — `Test Ruby (17, 34)` was cancelled during `Run RSpec` after 20 minutes. `Check for build success` failed. This shard gives no RSpec summary, so I cannot tell you if a test failed or the job stopped for a different reason. You must look at this one again.

These two PRs are below 6117. Their code is in the merge path. A fix must go in the PR that caused the problem, not in a PR above it.

## Two more problems

- **PR 6112** (the bottom of the stack) needs a rebase. Its base is commit `1333236`, which is 24 commits behind `origin/staging` (`603dddc`). All the CI results in this stack come from old staging code.
- **PR 6112** is BLOCKED. Its `Code owner review` check has the state FAILURE.

## The general rule

A green mark on the top PR of a stack is never proof that the layers below it are good. Each PR gets its own CI run against its own base. GitHub does not combine these results. In this case the top PR also has no diff, so its CI had nothing to test.

## What to do next

1. Fix the RSpec failure in PR 6114, in that PR.
2. Find why the shard in PR 6116 was cancelled, then fix it in that PR.
3. Rebase the stack on current staging from PR 6112 up.
4. Get the code owner review on PR 6112.
5. Read the CI result of each PR one at a time. Do not use 6117 as a summary of the stack.

I made no changes. I only read the repository and the GitHub data.

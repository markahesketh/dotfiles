---
name: babysit
description: Babysit a PR till its green
disable-model-invocation: true
---

Please watch the PR associated with this branch and check all review comments and build issues.

Set a cron to check every 2 minutes but backoff down to every 3 hours if nothing changes.

CI test runs take approximately 10 minutes. When you have just pushed a commit, schedule the next check around 10 minutes out rather than defaulting to a longer idle window.

If there are any unresolved review threads or failing tests or lint, except the "workflow" step, then we need to address them

There is relevant useful information in .claude/skills/address-ai-review/SKILL.md and .claude/skills/fix-ci/SKILL.md - have a look at those.

For all reviews and failures, triage, fix if obviously broken, confirm with user if any decision needs to be made, and be a diligent watcher with the aim of getting this PR ship-shape and ready to merge! All tests and lint passing, all review comments addressed and resolved, replied to with reasoning if we're not fixing.

**Fixing failing tests is the whole job.** If a test is failing on CI, it must be fixed — regardless of whether the failure appears related to this PR's changes, appears to be a pre-existing flake, appears to be a timezone/midnight/date-boundary issue, or appears to be caused by anything else. "Unrelated flake" is not a reason to skip a fix — it is a reason to fix it properly (deflake the test, pin the clock, stabilise the assertion, etc.). Do not dismiss failing tests with analysis about root cause; do not re-run hoping it passes without fixing the underlying issue. Either fix the test or, if a decision is genuinely needed, ask the user. Simply re-running `gh run rerun --failed` without addressing the cause is not acceptable.

Rebase on staging if necessary - If there are any conflicts, consider the changes on both branches and figure out what needs porting

Ask the user if any question arise as to how to proceed with merging the changes on both branches.

It is absolutely essential that the intent of changes from both branches are included in each branch even if architecture has changed or files have been deleted or moved.

Prioritise review comments as code changes will invalidate the test run anyway

Notify when the PR is ready, of if you get blocked with any issues or need user input
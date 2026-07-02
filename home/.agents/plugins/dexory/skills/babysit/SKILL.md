---
name: babysit
description: Babysit a PR till it's green
disable-model-invocation: true
---

Watch the PR on the current branch and drive it to a mergeable state: all tests and lint green, every review thread addressed and resolved. You're the orchestrator — watch, triage, delegate the actual fixing to sub agents (see Delegating the work), judge their results, and apply the winner. Don't do the fix work in this thread, and don't commit on your own (see the commit gate).

## Watch loop

Set a cron to check every 2 minutes, backing off to every 3 hours while nothing changes. CI runs take ~10 minutes, so after a push has just gone up, schedule the next check ~10 minutes out rather than a long idle window.

Each check: look at unresolved review threads and any failing tests or lint (ignore the "workflow" step). If everything is green and resolved, notify the user the PR is ready. Otherwise, work the issues below.

## What's in scope

This PR will be merged alongside other people's PRs. A fix you make for a problem this PR didn't cause can clash with someone else's fix landing first — so **only address problems caused by this PR's own changes.**

Before fixing a failing test, lint error, or build break, work out whether this PR caused it. The reliable test is: **does it also fail on the base branch?** If it fails there too, it's pre-existing — leave it alone. Likewise, don't take on dependency upgrades, CVE remediation, or other PRs' regressions that happen to surface here.

- **Caused by this PR** → fix it properly. If this PR made a test flaky, deflake it (pin the clock, stabilise the assertion, etc.) rather than re-running and hoping. Re-running `gh run rerun --failed` without addressing the cause isn't a fix.
- **Not caused by this PR** (pre-existing failure, another PR's regression, a CVE/dependency alert) → don't fix it. Note it to the user, and where a review thread raised it, reply explaining it's out of scope for this PR.

If you can't tell whether this PR caused something, or a genuine decision is needed, ask the user rather than guessing.

## Delegating the work

Don't fix things in this thread — babysit runs on a long-lived cron loop, so doing the work here bloats the context until compaction is forced. Triage scope here; delegate the fixing.

For each in-scope failing test and each review thread that needs a code change, spawn **three sub agents in parallel**, each independently solving the same problem from scratch. Give each its own worktree so they can apply changes and run the relevant tests without colliding. Each returns its proposed diff, a short rationale, and whether it validated (tests/lint pass).

Then judge for consensus:
- If two or more converge on the same approach, that's your consensus — take the cleanest implementation of it.
- If they diverge, or picking between them is a genuine judgment call, don't choose arbitrarily — put the options to the user.

Apply the chosen solution to the main working tree, then go to the commit gate. A sub agent never commits or pushes.

## Review threads

Prioritise review comments — pending code changes will invalidate the CI run anyway, so it's wasteful to chase a green build before the review is settled. For each in-scope thread, either delegate the fix (see Delegating the work) or, if you're not fixing it, reply with the reasoning — then resolve it. `.claude/skills/address-ai-review/SKILL.md` has useful detail here.

## Commit gate

**Prepare fixes in the working tree, then stop and ask before committing or pushing.** Don't run `git commit` or `git push` on your own initiative during the loop — surface what you've changed and get the user's go-ahead first. Once they approve, commit via the `commit-creator` skill (so work is split into atomic, conventional-commit-style changes) and push. Pushing is what triggers the next CI run, so the loop only advances past a fix once the user has approved it.

## Rebasing

When the branch is behind or has conflicts, **always rebase, never merge** — the job is to keep this branch's history clean on top of its base. Don't `git merge` the base branch in.

Don't assume the base is `main`/`master`/`staging` — it varies per repo (DexoryView targets `staging`, for example). Read it from the PR itself so this works everywhere:

```bash
BASE=$(gh pr view --json baseRefName -q .baseRefName)
git fetch origin "$BASE" && git rebase "origin/$BASE"
```

On conflicts, look at both sides and port intent across — it's essential that the intent of changes from both branches survives, even if files were moved, renamed, or deleted and the architecture shifted. If it's unclear how to reconcile the two, ask the user. The commit gate applies: don't push or force-push a rebased branch without approval.

## References

- `.claude/skills/fix-ci/SKILL.md` — CI failure triage
- `.claude/skills/address-ai-review/SKILL.md` — handling review comments
- `docs/guides/debugging-system-tests/README.md` — flaky system tests / Cucumber features

## Housekeeping

Notify the user when the PR is ready, or whenever you're blocked or need input.

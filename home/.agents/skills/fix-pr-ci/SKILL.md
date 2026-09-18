---
name: fix-pr-ci
description: Monitor a single pull request's CI run and fix the failures until the build is green. Use whenever the user asks to fix CI, fix the build, chase a red PR, deal with failing tests on a PR, or get a branch passing — including phrasings like "CI is red", "the build's broken", "get this green", or "why is my PR failing". For a chain of stacked PRs, use fix-stack-ci instead, which attributes failures to the right layer first.
---

# Fix CI on a pull request

The goal is a genuinely green build, not a build that has stopped complaining.
Those are different outcomes and the difference usually comes down to whether you
understood the failure before you changed anything.

## Orient first

Find the repo's own CI tooling before falling back to raw `gh` calls. Many repos
ship a wrapper that parses logs far better than you will by hand:

```sh
ls bin/ | grep -i -E 'ci|test|build'
cat CLAUDE.md AGENTS.md 2>/dev/null | grep -i -A5 'ci\b'
```

If you find something like `bin/ci-status`, read its `--help` and use it. It knows
the repo's workflow names, job layout and log format. Only fall back to the generic
path below when there is no local tooling.

Generic fallback:

```sh
gh pr checks <pr>                       # which checks failed
gh run view --job=<job_id> --log-failed # the failing output
```

## Extract the failing tests

`scripts/fetch_failing_specs` pulls the failed jobs for the current branch's PR and
extracts test identities — rspec paths and cucumber feature:line — into
`failing_specs.txt`. It derives the repo from `gh repo view`, so it works anywhere:

```sh
~/.claude/skills/fix-pr-ci/scripts/fetch_failing_specs
```

Pass a PR number to inspect one you are not currently on: `fetch_failing_specs 1234`.

This beats reading logs by hand because CI shards tests dynamically — the same
failure lands in a different job number on every run, so job names tell you nothing
stable. The test identity is the thing worth tracking.

## Reproduce before you fix

Run each failing test locally and confirm it actually fails. A test that passes
locally but fails in CI is a different problem — usually environment, ordering,
timezone or timing — and fixing the test body will not help.

If the repo has a system-test or flake debugging guide, read it before touching a
browser-driven test. Look for `docs/guides/debugging-system-tests/`, or grep the
repo's CLAUDE.md/AGENTS.md for "flake".

## Deciding what is actually wrong

When a test expects X and the code returns Y, exactly one of three things is true,
and they need opposite fixes:

- **The implementation is wrong** — fix the implementation.
- **The test setup is wrong** — it bypassed normal application flows and built
  invalid state, e.g. creating a record directly instead of through the factory or
  state machine that would populate its dependent fields. Fix the setup.
- **The expectation is wrong** — fix the test.

Start from the assumption that the test is right and the code is wrong, because
that is the common case. But check before acting: read the related specs and any
docs describing the behaviour. In repos where cucumber or similar specs define
business behaviour, those are the source of truth — a change that contradicts them
is a regression wearing a green tick.

Never edit business logic purely to silence a test. A build that is green because
the rule was deleted is worse than a red one, because now nobody knows.

If you cannot tell which of the three cases you are in, ask rather than guess. The
cost of asking is a message; the cost of guessing wrong is a silently broken rule.

## Flakes

A flaky test is a bug in the test, not a fact of life. Diagnose the root cause —
the usual suspects are waiting on state that has not settled, depending on
non-deterministic ordering, or assuming a timezone. Papering over it with a sleep,
a retry loop or a widened matcher converts an obvious failure into an invisible one.

## Working efficiently

CI runs are slow, so batch your fixes: get all the failures reproduced and fixed
locally, then push once. A push per fix turns a 20-minute feedback loop into a
whole afternoon.

Preexisting failures still count. So do failures someone already tried to fix.
CI does not grade on intent, and neither does the person waiting to merge.

## Waiting for the result

After pushing, wait for the run rather than polling in a tight loop. Either use a
background watcher that exits when the run finishes, or schedule a check at roughly
the length of a typical run for this repo.

Watch the workflow runs, not the PR's check list. A PR usually carries gates that
never conclude on their own: a required label, a review bot, a deploy approval. Those
sit pending indefinitely, so "every check has settled" is not a condition that can ever
come true, and a watcher waiting on it hangs long after CI finished. Poll the run IDs,
which do reach a terminal state:

```sh
until [ "$(gh run view <run-id> --json status -q .status)" = completed ]; do sleep 60; done
```

The same trap has a second form when reading `statusCheckRollup` directly. A commit
status (`__typename: StatusContext`) reports its result in `state`; a check run
(`CheckRun`) reports it in `conclusion`. Filter the whole list on an empty `conclusion`
and every commit status looks pending, including ones that already passed.

A cancelled or timed-out run is not a failure and not a pass. `gh pr checks` renders
`CANCELLED` exactly like `FAILURE`, so these masquerade as broken builds when they
actually need a re-run.

Repeat until every check passes. If you set up any recurring check while waiting,
remove it once the build is green.

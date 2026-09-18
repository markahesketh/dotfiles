---
name: fix-stack-ci
description: Fix failing CI across a whole chain of stacked pull requests by attributing each failure to the PR that introduced it, then fixing it there. Use whenever CI is red on more than one PR in a stack, or the user asks to "fix CI on the stack", "get the stack green", "sort out the failing tests across these PRs", "why is every PR in my stack red", or wants to rebase a stack that is failing. Also use when the same test appears to fail on several stacked PRs at once, since fixing it anywhere but the origin leaves the bug in the merge path. For a single standalone PR, use fix-pr-ci instead.
---

# Fix CI across a stacked PR chain

## Read the single-PR skill first

```sh
cat ~/.claude/skills/fix-pr-ci/SKILL.md
```

Read it now, before anything else, and treat it as the authority on **how to fix one
failure**: orienting on the repo's own CI tooling, reproducing before changing anything,
telling an implementation bug from bad setup from a wrong expectation, handling flakes,
and waiting on a run. Read the file rather than invoking the skill, so this works the same
way whether or not that skill is model-invocable.

Everything in that file applies here unchanged. This skill deliberately does not restate
its rules, because two copies drift: a rule added there must take effect here too, and it
only can if this skill defers instead of paraphrasing. What follows is **only what changes
when the PRs are stacked**.

## Why a stack changes anything

When one PR in a stack breaks a test, every PR above it inherits the failure. Eight
red PRs usually means one or two real bugs seen eight times.

That shapes everything here. The naive approach — walk the stack bottom to top,
fix, wait for CI, rebase, repeat — costs one full CI cycle per layer and takes a
day. Attributing all failures first, then fixing each at its origin in parallel,
costs about two cycles.

The rule that matters: **fix each failure in the PR that introduced it.** A fix
applied higher up looks green, but merging the origin PR on its own still ships the
bug into the trunk. Origin-fixing is the only sound rule, and everything below
exists to work out where the origin actually is.

## Phase 1 — Wait for complete data

Attribution over half-finished runs misfiles failures: a test whose true origin is
PR 1 gets blamed on PR 5 because PR 1's job had not reported yet. The collector
refuses to proceed while checks are pending, which is deliberate — let it stop you.

Wait for the runs as `fix-pr-ci` describes, including its warning about gates that never
conclude. One thing is sharper here: waiting costs one CI cycle, while attributing over
half-finished data costs a whole round of fixes aimed at the wrong layers.

## Phase 2 — Collect, keyed by test identity

```sh
python3 ~/.claude/skills/fix-stack-ci/scripts/collect_stack_failures.py
python3 ~/.claude/skills/fix-stack-ci/scripts/collect_stack_failures.py --json   # for scripting
```

It reads the stack order from `gh stack view`, pulls each PR's failed jobs, and
groups failures by **test identity** — never by job name, for the sharding reason
`fix-pr-ci` gives.

A stack adds a second constraint on what identity means: the **scenario or example name**,
not `file:line`. Line numbers are
not stable across a stack: a layer that adds so much as a comment above the test
shifts it, and the same scenario then appears under two keys with two different
origins — which is exactly the sort of phantom second bug this process exists to
avoid. When comparing by hand, compare names.

If the stack is not checked out locally, `gh stack checkout <pr>` first, or pass the
order explicitly with `--prs 111,112,113` (bottom to top).

Two categories the script separates out, both of which look like test failures in
`gh pr checks` and are not:

- **Red with no parseable test identity** — a build, lint or setup failure. Read it
  directly; there is no test to attribute.
- **No completed run** — cancelled or timed out, which `fix-pr-ci` warns reads as a
  failure. In a stack it does a second kind of damage: a PR that never finished cannot
  witness anything. Treat it as a hole in the evidence, not as a layer where a test
  passed, or you will conclude a bug was fixed at the layer that merely failed to report.

## Phase 3 — Confirm attribution against the code

The collector gives you a hypothesis from CI results. Confirm it from the repository
before acting, because CI evidence has a blind spot: a test absent from a PR's
failures might have passed, or might simply not have run in that shard. Those look
identical in the grid and imply opposite actions.

Git is authoritative and instant:

```sh
# Where does this symbol appear or disappear across the stack?
for b in $(git branch --list 'prefix/*'); do
  echo "$b: $(git grep -c 'SomeConstant' $b -- app/ features/ 2>/dev/null | wc -l)"
done

git log -S 'SomeConstant' --oneline <base>..<top>   # which commit introduced it
git diff <lower-branch>..<upper-branch> -- path/to/file
```

Two commands here usually beat an hour of waiting for another CI round.

## Phase 4 — Classify, because the fix differs

Each failure falls into one of five patterns, and handing the wrong one to an agent
wastes the round. The collector labels the first four; you judge the last.

**Propagating regression** — fails at its origin and at every PR above it, unbroken.
A genuine bug in that PR. Safe to hand to an agent. This is the common case.

**Fixed-higher** — fails from its origin up to some layer, then clears. A later PR
already contains the fix; it is just sitting in the wrong place. Do not write a new
fix. Move the existing hunk down to the origin PR, and expect the upper PR's copy to
become redundant and conflict during the rebase — plan for that rather than
discovering it mid-rebase.

**Unconfirmed** — failed on one layer only, and the layers above are green. This looks
exactly like fixed-higher and must not be treated as it. One red run cannot tell a real
regression that something above fixed from a flake that happened not to recur, and the two
demand opposite actions: move an existing fix down, or go and find out why a test is
unreliable. Re-run the layer, or read the diff of the layer above to see whether a fix is
actually in it. Only act once you know which you are looking at.

**Split-point error** — the PR references something introduced in a *later* layer,
so it cannot build or run on its own. The symptom is usually an undefined
constant, method or import. This is not a bug in the code; the commit is in the
wrong PR. The fix is moving code between layers, which no agent confined to one PR
can do. Handle these yourself as a stack operation.

**Flaky** — fails non-contiguously, with interior gaps. A real regression does not heal
and re-break as you move up the stack, so gaps mean the result is not reproducible. The
stack gives you this signal for free; what to do next is `fix-pr-ci`'s flake guidance.
Do not dispatch an agent at a flake on the strength of one run.

Before accepting "flaky", check whether the gap is a PR that could not report. A run that
was cancelled is the obvious case; a PR that **skipped** the check is the quieter one,
because a skipped check is terminal and renders green while having executed nothing. A
carrier branch with an empty diff skips most of the suite, so it looks like the layer where
everything started passing. A missing result is not a passing result, and mistaking one for
the other turns a straightforward propagating bug into an imaginary intermittent one, or
invents a fix that is not there.

## Phase 5 — Show the plan and stop

Present the attribution table, the classification and the intended fix per PR, then
wait for the user to confirm. Editing eight branches unattended on a guess is how a
bad attribution becomes eight bad commits. This checkpoint is cheap; skipping it is
not.

## Phase 6 — Dispatch, one agent per PR

Parallelise across PRs, never across failures within a PR. The unit of work is the
branch: two agents on one branch race on the same commit and push. One agent per
origin PR, handling every failure attributed to it.

Each agent needs its own git worktree, because a branch can only be checked out in
one place and agents sharing a checkout will collide:

```sh
git worktree add /tmp/stack-fix-<pr> <branch>
# ... agent works, commits, pushes ...
git worktree remove --force /tmp/stack-fix-<pr>
```

A bare worktree cannot boot Rails or run a browser test: no `node_modules`, no `.envrc`, no
generated `routes.js`, no test database. A global PostToolUse hook
(`~/.claude/hooks/prepare-worktree.sh`) provisions each worktree right after
`git worktree add`, when the repo's main checkout has `.scratch/bin/setup_worktree`, and
reports what it did. Read that report: it tells you whether commands must run as
`cd <worktree> && direnv exec . <cmd>` (DexoryView: yes, for `TEST_DB_NAME` and
`AEROPLANE_MODE`). If the hook reported nothing, the repo has no such script; work out
what a worktree needs yourself before dispatching, and pass it to the agents.

Tell each agent to read `~/.claude/skills/fix-pr-ci/SKILL.md` and follow it for the
per-failure loop, along with any repo-local CI guidance it points at. Then give it three
things it cannot work out alone:

- Exactly which failures are attributed to its PR, by test identity.
- That failures it may see from *lower* layers are being fixed elsewhere, and it
  must not fix them. Without this an agent will helpfully fix a lower PR's bug in
  the wrong layer, which is the exact thing this whole process exists to prevent.
- Its worktree path and branch, and that commands run through `direnv exec .`.

Reserve split-point and fixed-higher cases for yourself; they are structural moves
between branches, not per-PR work.

## Phase 7 — Rebase once, verify once

When every fix is pushed, cascade the stack in one go:

```sh
gh stack rebase          # --continue after resolving, --abort to restore
gh stack submit --auto
```

Use the `gh-stack` skill for the details. Do not hand-edit PR base branches or
rebase layers individually — that desynchronises the local chain from GitHub's
stack object.

Expect conflicts where a fix was moved down: the upper PR's now-redundant copy is
the usual culprit, and resolving in favour of the lower fix is normally right.

Then one verification round across the stack. If new failures appear, they are new
information — re-run the collector rather than assuming the old attribution holds.

## When the stack is the problem

If several PRs show split-point errors, the stack is split in the wrong places
rather than buggy. Say so plainly instead of patching each layer into working
independently — the patches are throwaway work and the real fix is `gh stack modify`
to reorder, which needs an interactive terminal and so needs the user to drive it.

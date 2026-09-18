---
name: fix-stack-comments
description: Address review feedback across a whole chain of stacked pull requests - inline threads, review bodies and plain PR comments alike - fixing each finding in the PR that owns the code rather than the PR it was posted on, then cascading the stack so every layer is correctly rebased. Use whenever review comments, review threads, CodeRabbit or AI-reviewer findings sit on more than one PR in a stack, or the user asks to "fix the comments on the stack", "address the reviews across these PRs", "sort out the review threads on my stack", "reply to the comments on all my PRs", or wants review feedback cleared before merging a stack. For a single standalone PR, use fix-pr-comments instead.
---

# Address review feedback across a stacked PR chain

## Read the single-PR skill first

```sh
cat ~/.claude/skills/fix-pr-comments/SKILL.md
```

Read it now, before anything else, and treat it as the authority on **how to handle one
piece of feedback**: how to decide whether a finding is legitimate, what a reply must
contain, when a thread may be resolved, and what "done" means. Read the file rather than
invoking the skill — it sets `disable-model-invocation`, so the Skill tool will not load
it, and the file is the reliable route.

Everything in that file applies here unchanged. This skill deliberately does not restate
its rules, because two copies drift: a rule added there must take effect here too, and it
only can if this skill defers instead of paraphrasing. What follows is **only what changes
when the PRs are stacked**.

## Why a stack changes anything

Running the single-PR process once per PR fails in three specific ways.

**A comment is not necessarily about the PR it sits on.** GitHub lets a reviewer anchor an
inline comment anywhere in a changed *file*, not only on changed lines, and a plain PR
comment has no anchor at all. So a finding raised on the top of the stack routinely
concerns code a lower layer introduced. Fix it where it was posted and the lower PR still
merges carrying the problem, while your fix becomes a conflict on the next cascade.

**One comment can span several layers.** The unit of work is already a finding rather than
a comment, and in a stack the findings inside one comment can each belong to a different
PR — so splitting a comment is not just bookkeeping, it decides which branch each fix
lands on.

**Eight independent pushes make a mess of the rebase.** Every fix on a lower layer
invalidates each layer above it. Eight agents each running the single-PR loop end to end
leaves eight branches to reconcile at once, with competing hunks wherever the same finding
got fixed twice.

So the rule is the one `fix-stack-ci` uses: **fix each finding in the PR that owns the
code**, and cascade exactly once, yourself, at the end.

## Phase 1 — Collect and attribute

```sh
python3 ~/.claude/skills/fix-stack-comments/scripts/collect_stack_reviews.py
python3 ~/.claude/skills/fix-stack-comments/scripts/collect_stack_reviews.py --json
```

It reads the stack order from `gh stack view`, gathers feedback from all three places it
hides, splits multi-finding comments into their separate findings, and attributes each to
a layer. It needs the branches locally, so `gh stack checkout <pr>` or `git fetch --all`
first. `--prs 111,112,113` (bottom to top) restricts it to part of the stack.

Review bodies and issue comments cannot be resolved, so the script treats one as
answered once the PR author has commented on that PR after it, and hides it. Pass
`--include-answered` to see them again. It also unwraps CodeRabbit's folded "Outside the
diff" and nitpick blocks, which are findings that never appear as threads, and drops the
status bodies, walkthroughs and rate-limit notices around them.

Do not skip it and read the PRs by eye. It covers the three objects `fix-pr-comments`
lists, and in a stack the anchoring difference between them decides how each finding can
be attributed at all: an anchored thread can be blamed to a line, while a review body or
issue comment has to be traced through the code it quotes.

Run it **before** any rebase. A force-push re-anchors threads: they return `isOutdated`
with a null line, and a thread with no live anchor cannot be blamed, so attribution you
could have had for free is gone.

### How it decides who owns a finding

Three signals, sharpest first:

1. **An anchored thread** — blame the line, map the commit to a layer.
2. **Quoted code** — run `git log -S` over the stack range for each distinctive fragment
   the reviewer quoted. This beats file-level attribution, which is often ambiguous: a
   spec file touched by two layers says nothing about which introduced the example being
   complained about.
3. **Named files** — which layers' diffs touch the paths mentioned in the prose.

Where signals conflict it says so and offers candidates rather than guessing.

Everything it prints is a hypothesis. Blame names the commit that last touched a line and
the pickaxe names commits that changed a fragment; neither proves that layer caused the
finding. A layer that reindented a block owns its lines without having introduced
anything. Confirm before moving a fix down:

```sh
git log -S 'SomeIdentifier' --oneline <trunk>..<top>
git diff <lower-branch>..<upper-branch> -- path/to/file
```

## Phase 2 — Evaluate, by the single-PR rules

Evaluate every finding exactly as `fix-pr-comments` says to: against the current code, one
decision per finding, fix or decline with a reason. Do not invent a different standard
here.

Two things a stack adds:

**Volume raises the stakes on rubber-stamping.** Forty findings across eight PRs is where
the temptation to accept unread lives, and a mistaken fix propagates up the whole stack.
Volume is a reason to be more careful per finding, not less.

**One extra decision per finding: which layer.** The single-PR process has nowhere else to
put a fix. Here you must also confirm the owning layer from Phase 1 before you accept it.

## Phase 3 — Spot what is not per-PR work

Three kinds need you rather than an agent:

**"This belongs in a different PR."** A reviewer questioning why a change sits in this
layer is asking for a stack restructure, not a code fix. That is `gh stack modify`, an
interactive TUI, so it needs the user to drive it. Say so instead of patching the layer
into looking right.

**A finding duplicated across layers.** One fix at the owning layer; on the copies, reply
pointing at it. Handing each copy to its own agent produces competing hunks that collide
during the cascade.

**A finding owned by the trunk.** The reviewer is pointing at pre-existing code. Often fair
and still not this stack's job. Raise it with the user; it may deserve its own PR.

## Phase 4 — Show the plan and stop

Present, per finding: where it was raised, which layer owns it, your fix-or-decline
decision, and which PR the change will land in. Then wait for confirmation.

This gate matters more than in the CI case. CI failures are facts; review feedback is
opinion, and your judgement about which opinions to accept is exactly what the user wants
a say in. Editing eight branches on forty unreviewed judgement calls is how a review round
becomes a mess.

## Phase 5 — Dispatch, one agent per owning PR

Parallelise across PRs, never across findings within a PR. The unit of work is the branch:
two agents on one branch race on the same commit and push.

An agent owns **every finding attributed to its PR, including ones raised on other PRs.**
Thread IDs are global, so it can reply without that PR checked out. One owner per finding
is what stops the same thing being fixed twice.

Each agent needs its own worktree, since a branch can only be checked out once:

```sh
git worktree add /tmp/stack-comments-<pr> <branch>
# ... agent works, commits, pushes its own branch ...
git worktree remove --force /tmp/stack-comments-<pr>
```

A bare worktree cannot boot Rails or run a browser test: no `node_modules`, no `.envrc`, no
generated `routes.js`, no test database. A global PostToolUse hook
(`~/.claude/hooks/prepare-worktree.sh`) provisions each worktree right after
`git worktree add`, when the repo's main checkout has `.scratch/bin/setup_worktree`, and
reports what it did. Read that report: it tells you whether commands must run as
`cd <worktree> && direnv exec . <cmd>` (DexoryView: yes, for `TEST_DB_NAME` and
`AEROPLANE_MODE`). If the hook reported nothing, the repo has no such script; work out
what a worktree needs yourself before dispatching, and pass it to the agents.

Tell each agent to read `~/.claude/skills/fix-pr-comments/SKILL.md` and follow it for the
per-finding loop — the path, not the skill name, for the reason given at the top. Then give
it the four things it cannot work out alone:

- Its worktree path and branch, and that commands run through `direnv exec .`.
- The exact findings it owns, with the decision already made for each, quoted in full.
- That findings it can see belonging to *other* layers are handled elsewhere and it must
  not touch them. Without this an agent will helpfully fix a lower layer's finding in the
  wrong branch, which is the thing this process prevents.
- **That it must push its own branch only, and must never run `gh stack rebase`,
  `gh stack sync`, `gh stack push` or `gh stack submit`.** Those rewrite every branch in
  the stack, and two agents doing it concurrently force-push over each other's work. The
  cascade is yours alone.

## Phase 6 — Reply, then cascade, then resolve

`fix-pr-comments` gives the order for one PR: fix, push, reply, resolve. A stack inserts
the cascade into the middle of it, and where it goes is not arbitrary.

**Reply before the cascade.** While a thread is still anchored the reviewer sees your reply
against the diff they commented on. After a force-push it is stranded on an outdated hunk.
Findings from a review body or issue comment have no anchor to strand, so for a stack
carrying only those, this constraint does not bite — say so rather than following it out of
habit.

Reply as `fix-pr-comments` prescribes — on the thread where there is one, otherwise one
comment per PR. Nothing about that changes here; only its position relative to the cascade
does.

**Cascade once, when every fix is pushed:**

```sh
gh stack rebase          # --continue after resolving, --abort to restore
gh stack submit --auto
```

Use the `gh-stack` skill for the details. Do not hand-edit PR base branches or rebase
layers individually — that desynchronises the local chain from GitHub's stack object.
Expect conflicts wherever a fix landed on a lower layer than the code that provoked it;
resolving in favour of the lower fix is normally right.

**Resolve after the cascade.** `fix-pr-comments` says to resolve only once a finding is
genuinely handled. In a stack that bar moves: a thread raised on #6117 but fixed on #6112
is not handled *on #6117* until the rebase propagates the fix there. Reply naming the
origin PR, resolve once it has landed.

When you reply about a cross-layer fix, name the PR it landed in and why there rather than
here. Reviewers do not track stack internals, and will otherwise read a resolved thread
with no visible change as being fobbed off.

## Done

Everything under "Done" in `fix-pr-comments`, plus:

- Every accepted fix sits in the PR that owns the code, once.
- The stack is cascaded and submitted, every layer based on the one below.
- Nothing is resolved that is not both replied to and actually present on that PR.

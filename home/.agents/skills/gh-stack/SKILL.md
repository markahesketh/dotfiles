---
name: gh-stack
description: >
  Manage GitHub stacked pull requests with the `gh stack` CLI. Use this whenever
  the user mentions a PR stack, stacked/dependent PRs, or asks to add, insert,
  place, move, reorder, submit, push, sync, rebase, merge, check out, or view
  work in a stack—including “add this to the PR stack”, “add this above PR #123
  and below PR #124”, “add/move to the top”, and “rebase the PR stack”.
---

# GitHub stacked PRs

Use `gh stack` for stack operations. Do not manually edit PR base branches or
recreate the stack with ad-hoc `git rebase` commands: `gh stack` keeps the local
branch chain and GitHub's Stack object in agreement.

A stack is ordered **bottom to top**. The bottom is closest to the trunk and
merges first; the top is furthest from the trunk and depends on everything
below it. Every PR should target the branch immediately below it.

## Before changing anything

1. Run `git status --short` and `gh stack view --json` to understand the current
   branch, stack order, PRs, and uncommitted work. Preserve unrelated changes.
2. Confirm `gh stack` is installed and GitHub authentication works. If it is
   missing, ask before installing it with `gh extension install github/gh-stack`.
3. Avoid commands that open a prompt or TUI in a non-interactive agent shell.
   Use explicit arguments and flags. If the repository has multiple remotes,
   pass `--remote <name>` (or verify `remote.pushDefault`).

## Choose the command

| User intent | Command |
|---|---|
| Start or adopt a stack | `gh stack init <bottom> <next> ... [--base <trunk>]` |
| Add a new local layer on top | `gh stack top` then `gh stack add <branch>` |
| Create/update the PRs and Stack on GitHub | `gh stack submit --auto` (`--open` for ready PRs) |
| Link branches/PRs into a stack (bottom to top) | `gh stack link <branch-or-pr> ...` (use `<stack-number>` first to append) |
| Check out a stack or layer | `gh stack checkout <stack-number-or-pr-number-or-url-or-branch>` |
| Inspect the stack | `gh stack view --json` |
| Fetch, rebase, push, and refresh PR state | `gh stack sync` (`--prune` when requested) |
| Rebase the chain | `gh stack rebase` (`--upstack` after changing a lower layer) |
| Push changed branches only | `gh stack push` |
| Merge stacked PRs | `gh stack merge <pr-or-stack-number> --yes` — never `gh pr merge` |

`init` and `link` take branches/PRs in bottom-to-top order. `add` must run
from the top branch. If the user's work is uncommitted, do not create a commit
without their approval; when they explicitly ask for that, `gh stack add -Am "<message>" <branch>` can stage, commit, and create the next layer in one step.

## Placement and reordering

Distinguish these requests:

- **“Add to the top”**: for a new local layer, use `gh stack top` followed by
  `gh stack add <branch>` and then `gh stack submit --auto`; for an existing
  branch/PR on a known remote stack, use `gh stack link <stack-number>
  <branch-or-pr> ...`.
- **“Go/check out the top”**: use `gh stack top`.
- **“Move/reorder this PR to the top” or “put it above/below PR #N”**: use
  `gh stack modify`, not `link`. `modify` is an interactive TUI: `i` inserts
  an empty branch below the selected layer, `I` inserts one above it, and
  Shift+Up/Down reorders. It requires a clean working tree and an active local
  stack. If the stack is remote-only, first use `gh stack checkout
  <pr-number-or-url>`. After applying the change, run `gh stack submit --auto`
  to push branches and update GitHub.
- `gh stack link` is additive and appends to the top; it cannot insert in the
  middle or reorder existing PRs. Do not pretend that listing PRs in a new
  order will perform a remote reorder. Never invoke the TUI from a
  non-interactive agent shell: explain the limitation and ask the user to run
  `gh stack modify`, or use an explicitly approved unstack/rebuild plan for an
  existing off-stack PR.

## Rebases and conflicts

Use `gh stack rebase` for a cascading stack rebase. Use `--upstack` to replay
layers above the current one after editing a lower layer, `--downstack` to
rebase from the trunk to the current layer, or `--no-trunk` to skip fetching
and rebasing the trunk. After resolving conflicts, stage the resolutions and
run `gh stack rebase --continue`; use `gh stack rebase --abort` to restore the
stack. If `gh stack sync` reports a conflict, it restores the branches first;
then run `gh stack rebase` interactively to resolve it.

After any local branch or structural change that affects existing PRs, submit
again with `gh stack submit --auto` (add `--open` only when requested). Report
the resulting stack/PR state, and do not merge or discard work unless the user
explicitly asked for it.

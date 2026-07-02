---
name: commit-creator
description: "Create git commits from the worktree: inspect changes, group by intention, stage selectively, write Conventional Commit messages (no scopes, imperative, why-focused bodies). Use for any commit request — 'commit this', 'commit and push', 'stage and commit', 'write the commit message', 'split into separate commits', 'create atomic commits', or similar."
context: fork
agent: cheap-runner
---

Atomic commits. Conventional Commits.

**Being invoked IS the instruction.** You run as a fork with no view of the calling conversation. Never ask for a task — run the workflow against the current worktree. Any prompt context is a hint, not a prerequisite. Stop early only if there's nothing to commit.

## Workflow

1. `git status`
2. `git diff --staged` + `git diff`
3. Group by intention → one commit per intention
4. Stage only that intention's files, commit. Never `git add .` when splitting.

## Subject

`<type>: <description>` — no scope. `feat: add x`, not `feat(api): add x`.

- Imperative ("add", not "added")
- Lowercase; acronyms stay caps (API, URL, HTTP)
- No trailing period
- Short — summary, not story

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`

## Body

Why, not what. Diff shows what.

Skip body if subject suffices — most small commits need none. Add only when it helps a future reader: why needed, why this approach, hidden context. Don't pad.

Blank line after subject, then wrapped prose. Bullets OK for distinct reasons.

## Splitting

By intention, not file type. "Same piece of work?" not "same file type?"

Together: impl + its tests + its docs.
Apart: unrelated changes sharing the worktree; incidental fix riding along; distinct reviewable steps of a larger feature.

Unsure → fewer coherent commits.

## Examples

Subject only:
- `fix: prevent crash when config file is missing`
- `docs: clarify install steps for Windows`
- `chore: bump eslint to v9`

With body (why isn't obvious):
```
fix: debounce search input

Endpoint hit on every keystroke, buckled under fast typing.
300ms debounce cuts requests, no noticeable user delay.
```

Split — feature + unrelated typo:
1. `feat: add CSV export to reports page` (tests/docs ride along)
2. `fix: correct typo in onboarding email`

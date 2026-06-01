---
name: create-commits
description: "Create one or more git commits from the current worktree: inspect changes, group them by intention, stage the right files, and write Conventional Commit messages (no scopes, imperative, why-focused bodies). Use this for any request to commit code or prepare commits — 'commit this', 'commit and push', 'make the commit', 'stage and commit', 'write the commit message', 'split this into separate commits', 'create atomic commits', or similar commit-related requests."
---

Create atomic, well-formatted git commits using Conventional Commits.

## Workflow

1. `git status` — see what's staged and unstaged
2. `git diff --staged` and `git diff` to understand the changes
3. Group the changes by *intention*; plan one commit per intention
4. For each commit, stage only the files that belong to it, then commit
   (don't reflexively `git add .` when you're splitting)

## Subject line

Format: `<type>: <description>` — no scope. Use `feat: add x`, never `feat(api): add x`.

- Imperative mood: "add", "fix", "remove" — not "added" / "fixes"
- Lowercase the description; keep acronyms uppercase (API, URL, HTTP)
- No trailing period
- Keep it short — it's a summary, not the whole story

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`

## Body: explain *why*, not *what*

The diff already shows *what* changed — don't restate it. The body exists to
capture what the diff can't: why the change was needed, what problem it solves,
why this approach over an obvious alternative, or context a future reader (human
or agent) would otherwise have to reverse-engineer.

If the subject line says everything worth saying, **write no body**. Most small,
self-explanatory commits don't need one. Add a body only when it genuinely helps
someone understand the change later — and then only as much as that takes. Don't
pad or write for the sake of writing.

Format: blank line after the subject, then wrapped prose (bullets are fine for
distinct reasons).

## Splitting commits

Split by **intention**, not by file type. The question is "is this the same
piece of work?" — not "is this the same kind of file?"

Commit *together*:
- Implementation with its tests
- Implementation with the docs describing it
- All the files that make up one coherent change

Split *apart*:
- Genuinely unrelated changes that happen to share the worktree
- A fix that's incidental to the feature you were building
- Distinct steps of a larger feature that are each reviewable on their own —
  split to make review easier, not for its own sake

When unsure, prefer fewer coherent commits over many fragmented ones.

## Examples

Subject only (no body needed):
- `fix: prevent crash when config file is missing`
- `docs: clarify install steps for Windows`
- `chore: bump eslint to v9`

With a body (the why isn't obvious from the diff):
```
fix: debounce search input

The endpoint was hit on every keystroke and buckled under fast typing.
A 300ms debounce cuts request volume with no noticeable delay for users.
```

Splitting — a worktree with a new feature plus an unrelated typo fix:
1. `feat: add CSV export to the reports page`  (its tests and docs ride along here)
2. `fix: correct typo in onboarding email`

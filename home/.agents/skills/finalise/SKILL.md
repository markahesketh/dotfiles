---
name: finalise
description: Pre-commit quality pass over the current branch's changes — reviews the diff with fresh eyes and strips debug statements, AI slop, false starts, abandoned approaches, and dead code introduced while building.
context: fork
model: opus
---

# Finalise

Prepare this branch's changes for commit. Judge what's actually on the page, not what it was meant to be.

Scope everything below to the changed lines identified in step 1. Pre-existing code — even if it looks messy or dead — is out of scope unless the user asks; touching it inflates the diff and buries the real work.

## 1. Survey the diff

Check `git status --porcelain` first. If it reports staged, unstaged, or untracked changes, that's work in progress — scope the review to just that: `git diff HEAD`, plus any untracked files from the status output (they won't appear in the diff). If the tree is clean, there's nothing uncommitted to isolate, so review the whole branch instead: find the base branch (`gh repo view --json defaultBranchRef -q .defaultBranchRef`, falling back to `main`/`master`) and run `git diff <base>`.

Read each changed file in full so you see the new code in its real context — but keep your edits to the changed lines.

## 2. Strip development artifacts

Things added to build or debug and never cleaned up:
- Debug output: `console.log`, `print`, `pp`, `var_dump`, `dump`, `dd`, `debugger`, `binding.pry`, `binding.irb`, `byebug`
- `TODO`/`FIXME`/`HACK`/`XXX` comments added on this branch
- Logging added only to diagnose a problem

## 3. Remove false starts and dead code

Abandoned approaches leave residue. Within the changed lines, remove:
- Commented-out earlier attempts
- Branches, conditions, imports, variables, or functions belonging to a discarded approach
- Logic replaced but not fully removed, and the paths it left unreachable

## 4. Remove AI slop

Patterns that break from the surrounding code and read as machine-authored:
- Defensive checks or try/catch that are abnormal for this codebase, especially on trusted or internally-validated paths
- `any` casts (or equivalents) papering over a type issue
- Spacing, naming, or structure that breaks the file's conventions

## 5. Simplify what you over-built

Exploration leaves things bigger than they need to be:
- Premature abstractions or helpers used only once — inline them
- Convoluted flows worth straightening now the shape is settled

Leave code that's genuinely clean alone. A comment that explains *why* (a non-obvious constraint, a gotcha) earns its place — don't strip it just because it's a comment.

## 6. Verify and report

Run the project's build and tests; confirm behaviour is unchanged. Then summarise in 3–5 sentences what you removed and why.

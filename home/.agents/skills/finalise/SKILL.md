---
name: finalise
description: Pre-commit detritus pass — strips debug statements, dead code, false starts, and AI slop from the current branch's diff.
context: fork
model: opus
---

# Finalise

Prepare this branch's changes for commit. Judge what's actually on the page, not what it was meant to be.

Scope everything below to the changed lines identified in step 1. Pre-existing code — even if it looks messy or dead — is out of scope unless the user asks; touching it inflates the diff and buries the real work.

## 1. Survey the diff

Scope is decided by whoever invoked you: if a caller (e.g. the `land` skill, or the user's prompt) gave you a diff range or base branch, review exactly that (`git diff <range>`, or `git diff <base>...HEAD`). Otherwise default to the working-tree changes — `git diff HEAD` plus untracked files (`git ls-files --others --exclude-standard`); if that's empty, say so and ask for a base.

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

## 5. Verify and report

Run the project's build and tests; confirm behaviour is unchanged. Then summarise in 3–5 sentences what you removed and why.

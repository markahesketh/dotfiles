---
name: finalise
description: Pre-commit quality pass. Reviews all session work with fresh eyes before committing. Removes debug statements, AI slop, false starts, abandoned approaches, and dead code. Combines deslop and refactor into a single comprehensive cleanup. Use when the user says "finalise", "finalize", "ready to commit", "pre-commit cleanup", "clean this up before committing", or "quality pass".
---

# Finalise

Review everything changed in this session and prepare it for commit. Approach it with fresh eyes — forget what you were trying to do and assess what's actually there.

## Workflow

### 1. Survey the diff

Run `git diff` against the base branch. Read every changed file in full, not just the hunks. Build a complete picture of what changed and why.

### 2. Find and remove false starts

Look for evidence of approaches that were tried and abandoned:
- Commented-out code from earlier attempts
- Dead branches or conditions introduced and never used
- Scaffolding added to debug a problem and never removed
- Logic that was replaced but not fully cleaned up
- Imports, variables, or functions that were part of a discarded approach

### 3. Remove debug statements

Strip all temporary development artifacts:
- `console.log`, `print`, `pp`, `var_dump`, `dump`, `dd`
- `debugger`, `binding.pry`, `binding.irb`, `byebug`
- `TODO`, `FIXME`, `HACK`, `XXX` comments added during this session
- Any logging added purely to diagnose a problem during development

### 4. Remove AI slop

Check for patterns inconsistent with the surrounding codebase:
- Comments a human wouldn't write, or that narrate obvious code
- Comments inconsistent with the style of the rest of the file
- Excessive defensive checks or try/catch blocks that are abnormal for this codebase (especially in trusted or internally-validated codepaths)
- Casts to `any` or equivalent to work around type issues
- Style that doesn't match the file — spacing, naming, structure

### 5. Refactor for simplicity

- Remove dead code and unreachable paths
- Straighten logic flows that became convoluted during development
- Remove excessive parameters, especially ones added "just in case"
- Remove premature abstractions or helpers created for a one-time use
- Revert over-engineering introduced while exploring solutions

### 6. Verify

Run build and tests. Confirm behavior is unchanged.

### 7. Report

Summarise what was changed in 3–5 sentences. Be specific about what was removed and why.

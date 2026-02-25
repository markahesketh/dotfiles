---
name: add-tests
description: Add missing, relevant, and high-value tests for recently completed work. Use when the user asks to add tests or specs, mentions missing test coverage, or wants to verify their work is tested. Trigger phrases include "add tests", "add specs", "write tests", "missing tests", "test coverage", "untested", "need specs".
---

# Add Tests

Review everything that has changed in this session and assess it with fresh eyes to identify missing, high-value tests.

## Process

### 1. Gather context from the conversation

Read back through the conversation to understand:
- What was built or changed
- What decisions were made
- Any edge cases or tricky logic that was discussed

### 2. Identify all changed code

Run these git commands to find everything touched:

```bash
# Unstaged and staged changes
git status
git diff
git diff --cached

# Determine if we're on the default branch
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'
git branch --show-current
```

If on a non-default branch, review all commits since branching:
```bash
git log --oneline $(git merge-base HEAD origin/main)..HEAD
git diff $(git merge-base HEAD origin/main)..HEAD
```

If on the default branch, review the last 3-5 commits:
```bash
git log --oneline -5
git diff HEAD~3..HEAD
```

### 3. Read the changed files

For each file that was modified, read it in full to understand:
- What the code does
- What inputs it accepts
- What outputs or side effects it produces
- What could go wrong

### 4. Assess test coverage with fresh eyes

Look at existing tests (if any) and ask:
- What is already covered?
- What is not covered at all?
- What is covered but only superficially?
- Are both happy paths and sad/error paths tested?
- Are edge cases handled? (empty input, nil/null, boundary values, concurrent access, etc.)

### 5. Prioritise high-value tests

Focus on tests that:
- Verify core business logic or domain rules
- Cover error handling and failure modes
- Test integration points between components
- Guard against regressions in non-obvious behaviour

Deprioritise:
- Trivial getters/setters with no logic
- Framework boilerplate that doesn't need testing
- Tests that duplicate existing coverage

### 6. Write the tests

Follow the project's existing test conventions:
- Same framework, file structure, and naming patterns already in use
- Co-locate tests with the code they test (or in the expected test directory)
- Use descriptive test names that read as documentation
- Each test should have a clear arrange / act / assert structure
- Cover at least one happy path and the most likely failure modes per unit

### 7. Verify

After writing, confirm the tests:
- Can be found and run by the test framework
- Pass for correct code
- Would catch the bugs they're meant to catch (reason through it if you can't run them)

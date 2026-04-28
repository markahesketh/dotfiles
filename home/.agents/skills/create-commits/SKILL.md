---
name: create-commits
description: "Create one or more git commits from the current worktree: inspect changes, stage appropriate files, split unrelated work into atomic commits, and write clear conventional commit messages. Use this for any request to commit code or prepare commits, including prompts like 'commit this', 'make the commit', 'stage and commit', 'write the commit message', 'split this into separate commits', 'create atomic commits', or similar commit-related requests."
context: fork
model: sonnet
agent: true
---

Create atomic, well-formatted git commits using conventional commit conventions.

## Workflow

1. Run `git status` to check staged files
2. If no files staged, run `git add .` to stage all changes
3. Run `git diff --staged` to analyze the changes
4. If changes touch multiple unrelated concerns, split into separate commits
5. For each commit, create a message following the format rules below

## Commit Message Format

```
<type>: <description>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc)
- `refactor`: Code changes that neither fix bugs nor add features
- `perf`: Performance improvements
- `test`: Adding or fixing tests
- `chore`: Build process, tools, dependencies

**Rules:**
- Imperative mood ("add feature" not "added feature")
- Lowercase after the colon
- No period at the end

## Splitting Commits

Split when changes involve:
- Different concerns or unrelated parts of codebase
- Different types of changes (features mixed with fixes)
- Different file types (source vs documentation)
- Large changes that would be clearer separated

Each commit should be atomic and serve a single purpose.

**Never split tests from the implementation they test.** If a feature, fix, or refactor includes tests, commit the implementation and its tests together in the same commit. A `feat:` or `fix:` commit may include test files — do not separate them into a standalone `test:` commit.

## Examples

Good:
- `feat: add user authentication system`
- `fix: resolve memory leak in rendering`
- `docs: update API endpoint documentation`
- `refactor: simplify parser error handling`
- `chore: update package dependencies`

Splitting example:
1. `feat: add new API type definitions`
2. `docs: update documentation for new types`

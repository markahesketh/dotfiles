---
name: pr
description: "Create a GitHub Pull Request from the current branch: push the branch, choose the right base branch, prepare the PR title and description, and open a draft PR for review. Use this for requests like 'create a PR', 'open a pull request', 'submit this for review', 'push this and make a draft PR', 'raise a PR', or similar GitHub review-submission requests."
context: fork
agent: cheap-runner
---

Push current branch, open draft GitHub PR. Show description, wait for approval, then create.

## Base branch

Detect, never assume:
```bash
DEFAULT_BRANCH=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')
```
Empty/fails → ask user. Always pass `--base "$DEFAULT_BRANCH"` to `gh pr create`. Implicit default has produced wrong-base PRs (repo default `staging`, PR opened against `main`).

## Tracking refs (Jira/Basecamp)

Forked context — no parent conversation. Find refs in order:
1. Invocation message — authoritative. Caller passes Jira keys + full Basecamp card URLs.
2. `git log -20 --pretty=%s` and `git rev-parse --abbrev-ref HEAD`.
3. Ask user.

## Title

- Jira linked: `[APS-123] Descriptive title`
- Else: clear summary.

## Description

Concise. Reviewer reads the diff — don't restate it. Non-engineer-readable (PM/QA): user-facing change, why, what to focus on. No file-edit changelogs.

**Tracking links** (if any): bare markdown links on the first lines, before any heading. Jira first, then Basecamp. Card URL as-is. Blank line after.
```
[Jira ticket](https://organisation.atlassian.net/browse/APS-123)
[Basecamp card](https://3.basecamp.com/.../cards/55510)
```

**Bug fix:**
```
## Issue
<bug>
## Fix
<resolution>
```

**Feature:** 1–2 sentence description. Add `## Key Changes` bullets only for multiple significant changes.

## Never

- 'Test plan' or 'Summary' headings
- Co-author / Claude / AI / automation mentions
- Over-explaining small changes

## Workflow

1. Detect `$DEFAULT_BRANCH`.
2. Find tracking refs.
3. Push branch.
4. Draft title + description.
5. Show user: description + `Base: $DEFAULT_BRANCH`. Wait for approval.
6. `gh pr create --draft --base "$DEFAULT_BRANCH" --title "..." --body "..."`.

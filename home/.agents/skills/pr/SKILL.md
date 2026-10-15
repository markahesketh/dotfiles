---
name: pr
description: "Open a GitHub pull request. Use this instead of running `gh pr create` yourself, every time you open a PR — whether the user asks ('create a PR', 'raise a PR', 'open a PR', 'push and open a PR', 'submit this for review') or opening a PR is a step in a larger task."
---

The PR body is a **briefing** for one busy reviewer, not a record of the work. Be concise. Write in ASD-STE100 Simplified Technical English.

## Workflow

1. **Inspect:** `<skill-dir>/scripts/inspect.sh [base]`. Pass the base when the branch is stacked, or the repo releases from a non-default branch.
2. **Prove:** answer "Give me irrefutable proof that this works now." Use this session's evidence; if it is not irrefutable, run the change or ask the user.
3. **Draft** the body to a file with the Write tool, then run the unslop skill (pstack:unslop) over it.
4. **Confirm** the base, title, body, and attachments with the user. Wait for approval.
5. **Create:** `bash <skill-dir>/scripts/create.sh --base <base> --title "<title>" --body-file <path> [--attach /abs/path]...`. Opens a draft; add `--ready` only when asked.
6. **Report** the PR URL and any uncommitted files from the snapshot. Commit nothing.

## Title

Prose that says what the PR delivers, with no Conventional Commit prefix: "Show the scan date on the location page".

## Body

Write only what the diff cannot show: the problem or feature, its impact, key context (issues, dependencies, breaking changes), and what needs careful review — name the file or decision. Omit what GitHub shows: branch, commits, file counts.

- First line: Basecamp/Jira links. Then a short summary.
- Then `###` headings, in this order, worded exactly: `Issue` (`What it does` for a feature), `Fix`, `Proof`, `Important`. Cut near-empty headings. Add another (e.g. `Excluded`) only for a genuine extra point.
- Bullets for lists, prose for reasoning. A few bullets or two to three sentences per section.

## Proof

Irrefutable: the reviewer sees it work as a user does, or can repeat the steps and get the same result. "I tested it", unit tests, and CI are not proof.

Use the form that fits; combine if needed:

- **UI:** screenshots or video, before and after.
- **Acceptance criteria:** checklist, each with how it was checked.
- **Bug fix:** repro steps, result before and after.
- **Performance:** before/after table, with method and data set.
- **API/CLI/backend:** the command and trimmed output.
- **Data/migration:** the query and before/after counts.

Rules:

- Never invent a result. Leave unchecked criteria unticked, with the reason.
- Capture media yourself to `/tmp/pr-<branch>/`; if you cannot, ask the user. No placeholders.
- Reference media by absolute path, and pass the same path to `--attach`; gh swaps in the uploaded URL. Put a video alone on its line.
- No observable behaviour change (refactor, dependency bump): drop `Proof`, and say in `Fix` what makes it safe.

## Example

```
[Basecamp](https://app.basecamp.com/...) | [Jira](https://dexory.atlassian.net/jira/...)

Show the scan date on the location page.

### Issue

Users cannot tell how old a location's data is.

### Fix

Add the last scan date to the location header.

### Proof

| Before | After |
| --- | --- |
| ![No scan date](/tmp/pr-scan-date/before.png) | ![Scan date shown](/tmp/pr-scan-date/after.png) |

- [x] Date shows in the user's timezone — checked on staging as UTC and BST users
- [ ] "Never scanned" state — not checked: no such location on staging

### Important

- `formatScanDate` falls back to UTC when the site has no timezone.
```

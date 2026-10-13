---
name: pr
description: "Open a GitHub pull request. Use this instead of running `gh pr create` yourself, every time you open a PR — whether the user asks ('create a PR', 'raise a PR', 'open a PR', 'push and open a PR', 'submit this for review') or opening a PR is a step in a larger task."
---

The PR body is a **briefing** for one busy reviewer. Write it as a briefing, not as a record of the work.

Be concise. Write in ASD-STE100 Simplified Technical English.

## Workflow

1. **Inspect.** `<skill-dir>/scripts/inspect.sh <base>` — one read-only snapshot:
   base branch, current branch, uncommitted files, and the commits and diff the
   reviewer will see. Pass an explicit base as the first argument when the branch
   is stacked on another feature branch, or when the repository releases from
   something other than its default branch.
2. **Draft the briefing** from the commits and the diff in that snapshot. Write
   it to a file with the Write tool, so `--body-file` carries it and shell
   quoting cannot break it.
3. **Confirm.** Show the user the proposed base, title, and body, and wait for
   approval. The PR is created as a draft; add `--ready` in step 4 only when
   the user asks for a ready PR.
4. **Create the PR** with the script:

   ```
   bash <skill-dir>/scripts/create.sh --base <base> --title "<title>" --body-file <path>
   ```

   It pushes the branch, then opens the PR, and prints the URL on its last line.
5. **Report the PR URL.** Also report any file the snapshot showed as uncommitted.

Uncommitted work stays uncommitted. This skill commits nothing.

The work is done when the PR URL is reported.

## The title

Write the title as succinct prose that says what the PR delivers: "Show the
scan date on the location page". Conventional Commit prefixes belong on commits,
so a PR title starts with the first word of the sentence.

## The briefing

Say what the PR delivers:

- The problem solved, or the feature added.
- The user-facing or system-level impact.
- Key context: related issues, dependencies, breaking changes.
- Important areas that need careful review, where such areas exist.

Keep it high-level. Reviewers are intelligent and busy, so respect their time,
and write only what the diff cannot show them. Name a file, a function, or a
design decision when the reviewer must scrutinise it: complex logic, an edge
case, a security concern, an architectural choice.

## Format

Link any related Basecamp cards or Jira tickets at the top, then open with a short summary of what the PR delivers. 
Then make the rest scannable in seconds:

- Use these `###` headings, in this order, worded as written: `Issue`, `Fix`,
  `Important`. Same word in the same place on every PR, so a reviewer who reads
  several of mine knows where to look.
- The first heading names the driver, so `Issue` on a bug fix becomes `What it
  does` on a feature. Cut any heading whose body is near-empty: a
  refactor with nothing to warn about is a summary and a `Fix` section.
- Add a fourth heading only when the PR has a genuine fourth thing to say, for
  example `Excluded` for scope deliberately not covered.
- Use bullets for anything enumerable: causes, deliverables, affected
  environments, verification results. Use prose for a genuine narrative, or for
  a judgement call that needs its reasoning.
- Keep each section to a few bullets, or to two or three sentences.
- Leave out what the platform already shows: target branch, commit list,
  changed-file counts.
- Only include a testing section if it's noteworthy.

Example:

```
[Basecamp](https://app.basecamp.com/...) | [Jira Ticket](https://dexory.atlassian.net/jira/...)

The short summary goes here.

<screenshots>

### Issue

A brief summary of the problem, if there was one.

### Fix

A brief summary of the fix, if there was one.

### Important

- Something here
- And another thing
```

---
name: pr-human
description: "Open a PR for review. Use this for requests like 'create a PR', 'open a pull request', 'submit this for review', 'push this and make a draft PR', 'raise a PR', or similar GitHub review-submission requests."
---

Invoke the /tone-of-voice skill to write a clear, concise pull request description. 

Your goal is to help reviewers understand what this PR accomplishes without overwhelming them.

Core principles:
- Describe WHAT this PR delivers, not the implementation details or how it works
- Keep it high-level. Reviewers can examine diffs for technical specifics
- Assume reviewers are intelligent and busy, so respect their time
- Only surface file names, functions, or code details if there's a specific reason reviewers should scrutinize them (e.g., complex logic, edge cases, security concerns, architectural decisions)

What to include:
- The problem being solved or feature being added
- The user-facing or system-level impact
- Any key context (related issues, dependencies, breaking changes)
- Callouts for areas needing careful review (if applicable)

What to skip:
- Line-by-line changes
- Implementation approach or design patterns used
- Obvious refactoring details
- Generic function names or file paths (unless there's a reason to highlight them)

Format: structure it so a reviewer can scan it in seconds. A wall of prose paragraphs is hard to read even when every paragraph is short, so don't ship one.

- Use short `###` headings to separate the distinct things a reviewer needs: what was broken or being added, what the change does, what deserves careful attention, how it was verified.
- Use bullets for anything enumerable: causes, deliverables, affected environments, verification results. Reach for bullets first, and fall back to prose only where the point is a genuine narrative or a judgement call that needs its reasoning.
- Keep each section short, a few bullets or two to three sentences. If a heading would carry a near-empty body, cut the heading.
- Skip anything the platform already shows: target branch, commit list, changed-file counts.
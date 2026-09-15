---
name: review-pr
description: Post a GitHub PR review that surfaces only merge-blocking issues, while reporting non-blocking observations separately for the user's decision.
disable-model-invocation: true
---

# Reviewing a PR and posting it to GitHub

This skill produces one GitHub review per PR: a short top-level comment plus a set of inline comments attached to specific lines, submitted via `gh api`. It also gives the user a separate summary of non-blocking observations so they can decide what to do with them. The point is to protect the PR author's time and the reviewer's credibility: every comment posted by default should be something worth interrupting the merge for, phrased plainly, with nothing that reads as nitpicking or padding.

Two bundled scripts live in this skill's `scripts/` dir. You are given the skill's base directory when the skill loads; substitute it for `<skill-dir>` below.

## What counts as blocking

Assess findings at two levels:

- **Blocking:** a real problem such as a correctness bug, security issue, data-loss or data-integrity risk, broken API contract, or missing error handling for a failure that will plausibly happen in production. These findings may be posted in the GitHub review.
- **Non-blocking:** a substantive observation that is worth the user's attention but does not justify interrupting the merge. Include each one in the user-facing summary with its location, the concern, and an explicit reason why it does not meet the blocking threshold. Do not put them in the GitHub review by default.

Non-blocking observations are for the user's decision. Do not add them to the posted summary or inline comments unless the user explicitly asks for specific observations to be posted. Do not use this category to revive items the skill explicitly excludes below, such as style preferences or visible CI status.

Weigh likelihood before classifying a finding. If a failure mode requires a rare or contrived sequence of events, it isn't worth blocking the PR over; if it is still useful for the user to consider, record it as non-blocking. Assume the PR author is competent and acted in good faith: if something looks unusual, first consider whether it's an intentional, reasonable choice you're missing context on, rather than assuming it's wrong.

Never raise, even if technically true:
- Failing tests or CI status — that's visible on the PR already and isn't your call to relitigate.
- Outdated or vulnerable dependencies — handled elsewhere, not part of this review.
- Style, formatting, or naming preferences.
- Missing or incomplete documentation/comments.
- Performance nitpicks that don't matter at the PR's actual scale.
- Alternative implementations that are simply a matter of taste.

If, after reading the diff, nothing rises to the blocking bar, say so plainly and do not post a review by default. List any non-blocking observations separately. A review with zero comments and a forced "looks good" is worse than no review.

## Steps

1. **Identify the PR.** Use whatever was provided (a URL, a number, "that PR" referring to something just discussed). If it's ambiguous which PR or which repo, ask rather than guessing. A full URL works for PRs in any repo; a bare number is resolved against the repo of the current directory.

2. **Gather everything in one shot:**

   ```
   python3 <skill-dir>/scripts/gather_pr_context.py <pr-number-or-url>
   ```

   This prints the PR's metadata, changed files, head commit, and — importantly — every existing review, inline review comment, and issue comment already on the PR. It writes the full diff to a file and prints its path as `diff_path`; read that file. Read the diff properly, not just the file list.

   The diff alone often isn't enough to judge behaviour. To read surrounding code at the PR's head, either `gh pr checkout <number>` (if the working tree is clean and you're happy to switch branches) or fetch individual files with `gh api repos/<repo>/contents/<path>?ref=<head_commit> --jq .content | base64 -d`. Don't rely on the files in the current checkout — it may be on a different branch.

3. **Check what's already been said** before drafting anything. If another reviewer (or a bot) already raised a point, don't repeat it — that's noise, not a second opinion. If a concern was raised and there's a later commit or reply addressing it, treat it as resolved unless the diff shows otherwise.

4. **Find and classify issues** per the bar above. For each blocking issue, note the exact file path and line number. Also record non-blocking observations separately, with their location, the concern, and the reason each one does not justify blocking. Keep the two groups distinct so a non-blocking observation cannot accidentally become a posted comment.

   GitHub only accepts inline comments on lines that appear in the diff — added or context lines in a hunk, numbered by the new file (`side: RIGHT`, the default). To comment on a deleted line, use the old file's line number and `"side": "LEFT"`. A comment on any other line makes GitHub reject the entire review, so if the problem is in code the PR didn't touch, anchor the comment to the nearest changed line that calls or depends on it and say so in the comment. The post script checks every anchor against the diff before posting and tells you which ones are wrong.

5. **Draft the report and review** using the `tone-of-voice` skill for every piece of written text.

   First prepare the user-facing summary:

   - Keep the blocking section to a couple of sentences: what is blocking and why it matters, not a restatement of every comment.
   - Add a clearly labelled **Non-blocking observations** section. For each finding, state the concern and why it is non-blocking (for example, its impact is limited or the failure path is unlikely in production). These are for the user's decision and are not part of the post payload by default.

   Then prepare the GitHub review draft. Its top-level body and inline comments must contain blocking findings only unless the user explicitly asks for particular non-blocking observations to be posted. An explicit request to post selected observations is required; confirmation of the overall draft does not grant that permission. Each inline comment should stand on its own next to the code it's attached to — say what's wrong and why it matters, skip preamble like "nit:" or "just a thought."

   Use `REQUEST_CHANGES` as the verdict. The one exception: GitHub refuses `REQUEST_CHANGES` on your own PR, so if `viewer_is_author` is true in the gathered context, use `COMMENT` instead.

6. **Show the full report and draft for confirmation before touching the API** — the user-facing summary, the non-blocking observations, the GitHub body, the verdict, and every inline comment with its file and line. Make clear which non-blocking observations are excluded from the payload. This is a hard stop: do not call `post_review.py` without `--dry-run`, or `gh api`, until the exact posted wording has been explicitly confirmed. If the user selects non-blocking observations for posting, add only those selected items, redraft, and show the revised payload again. If there are no blocking findings, do not post anything by default; say that there are no merge blockers and list the non-blocking observations instead.

7. **Post it.** Once confirmed, write the draft to a JSON file matching the shape below, including the `head_commit` from the gathered context, and run:

   ```
   python3 <skill-dir>/scripts/post_review.py <pr-number-or-url> <draft.json>
   ```

   ```json
   {
     "head_commit": "<sha from gather_pr_context.py>",
     "body": "brief top-level summary of blocking findings",
     "event": "REQUEST_CHANGES",
     "comments": [
       {"path": "src/foo.ts", "line": 42, "body": "inline comment text"},
       {"path": "src/bar.ts", "line": 7, "side": "LEFT", "body": "comment on a deleted line"}
     ]
   }
   ```

   The script refuses to post if the PR head has moved since the diff was gathered (the author pushed, so line numbers may have shifted — re-gather and redraft) or if any comment anchor isn't in the diff. Otherwise it submits everything as a single review via `gh api repos/{owner}/{repo}/pulls/{number}/reviews`, so the posted summary and inline comments land together, exactly like a manual GitHub review. Non-blocking observations stay outside this payload unless the user explicitly selected them. If only selected non-blocking observations are being posted, use `COMMENT`, not `REQUEST_CHANGES`; if blocking findings are also posted, keep the blocking verdict and clearly label the selected observations as non-blocking. Report back the review URL it prints.

   `--dry-run` runs the same checks and prints the payload without posting. Use it to validate anchors while drafting; it's safe to run before confirmation.

## Success looks like

- Nothing was posted without the exact wording being seen and confirmed first.
- By default, every comment posted is something that would genuinely justify blocking the merge — no style, docs, test-status, or dependency mentions slipped in.
- The user-facing summary is brief for blocking findings and lists non-blocking observations separately; the posted summary does not include non-blockers unless explicitly selected.
- Inline comments are anchored to the correct file and line, and read the way they'd actually be written (via `tone-of-voice`).
- If there was nothing blocking, no review was posted by default, and the absence of blockers plus any non-blocking observations was communicated plainly.

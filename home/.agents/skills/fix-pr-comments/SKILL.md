---
name: fix-pr-comments
description: Address review feedback on a single PR — inline threads, review bodies and plain PR comments from people and AI reviewers. Discuss each finding with the user before changing code or replying.
disable-model-invocation: true
---

# Address PR review

Evaluate every outstanding finding against the code, agree an outcome for each with the user, then fix or decline with evidence. Do no work until the user has agreed every outcome.

## Where feedback lives

| Object | Fetch with | Resolvable? | Reply |
|---|---|---|---|
| Review thread (inline) | `gh api graphql` → `pullRequest.reviewThreads` (`isResolved`) | yes | on the thread |
| Review body (approval / change request summary) | `gh api repos/{owner}/{repo}/pulls/{n}/reviews` | no | one PR comment per review |
| Issue comment (PR conversation) | `gh api repos/{owner}/{repo}/issues/{n}/comments` | no | one PR comment per comment |

`gh pr view` shows these unevenly — fetch all three. Outstanding means an unresolved thread, or a review body or comment the PR author has not answered.

The unit of work is a **finding**, not a comment. Split comments that hold several findings. Ignore bot scaffolding (e.g. CodeRabbit "draft PR not reviewed" notices).

## Steps

1. **Collect** every outstanding finding from all three objects.
2. **Verify** each claim against the current code. Reviewers can be wrong, outdated or preference-only, and a real finding can carry a wrong diagnosis — check the mechanism, not just the conclusion. Advisory feedback invites judgement, not compliance.
3. **Present and stop.** This step is read-only: no edits, commits, pushes, replies or resolves. Number each finding and give:
   - who raised it and where (file:line, or which review/comment)
   - the claim, in one line
   - your stance — fix or no change — with the code evidence
   - for a fix, the minimal change you propose

   Push back plainly where the reviewer is wrong; agree plainly where they are right. Then wait. Discuss until every finding has an agreed outcome and the user confirms the set.
4. **Fix** only the agreed changes, minimally. Run relevant verification.
5. **Commit** with the `commit` skill, using meaningful boundaries.
6. **Push.** If `git rev-parse --abbrev-ref --symbolic-full-name @{upstream}` fails, run `git push --set-upstream origin HEAD`; otherwise `git push`.
7. **Reply** to every finding, per the table. For fixes, say what changed (files, functions, tests). For declines, give the code-level evidence. If you accepted a finding but rejected its reasoning, say so. For review bodies and comments, cover all their findings in one reply, matching the reviewer's numbering. Write multi-line bodies to a temp file and pass the file to `gh`.
8. **Resolve** a thread only after its reply is posted and it is fully handled. Leave uncertain threads open. Never resolve just to clear the queue.

After the user agrees outcomes, run non-interactively. If a command fails, fix the cause and retry.

## Report

List each finding with its outcome: fixed (commit) or declined (one-line reason), and whether its thread was resolved.

---
name: fix-pr-comments
description: Fix PRs threads, comments and reviews from users and AI.
disable-model-invocation: true
---

Address PR Review Feedback

Invoke my `tone-of-voice` skill for responding.

Goal:
Evaluate every outstanding review finding against the code, then fix legitimate issues or decline with clear rationale. Do not clear findings without real evaluation.

Where feedback lives:
Three different objects, and only the first can be resolved. Reading only review threads misses the rest, and a detailed review sitting in the conversation tab is easy to miss entirely.

| Object | Anchored to a line? | Resolvable? | How to reply |
|---|---|---|---|
| Review thread (inline) | yes | yes | reply on the thread |
| Review body (summary on an approval or change request) | no | no | one PR comment |
| Issue comment (the plain PR conversation) | no | no | one PR comment |

The unit of work is a **finding**, not a comment. One comment often holds a numbered list of several independent findings about different files; treat each as its own decision. Ignore auto-generated bot scaffolding (CodeRabbit "draft PR not reviewed" notices and similar) — it is not feedback.

Rules:
- Use standard git plus the repository forge CLI for pull request or merge request operations: `gh` for GitHub, `glab` for GitLab.
- Inspect the current repo and existing pull request or merge request state before choosing commit messages, titles, bodies, or replies.
- Prefer repository conventions and existing templates when present.
- Invoke the `/commit` skill all new commits
- Use explicit push logic: check upstream with `git rev-parse --abbrev-ref --symbolic-full-name @{upstream}`; if absent, run `git push --set-upstream origin HEAD`, else run `git push`.
- Execute commands non-interactively and continue until the requested outcome is complete.
- For multi-line pull request or merge request content, write it to a temp file or heredoc and pass the file to the forge CLI instead of inline multi-line body text.
- If a command fails, resolve the issue and retry rather than stopping early.

Steps:
1. Collect every outstanding finding from all three objects above before responding, splitting multi-finding comments into their separate findings. `gh pr view` surfaces these unevenly; read review threads, review bodies and issue comments explicitly.
2. Verify each claim against the current code. Comments can be wrong, outdated, or preference-only, and a stated diagnosis can be wrong even when the finding is real — check the mechanism the reviewer describes, not just the conclusion. Feedback marked advisory or non-blocking invites judgement rather than compliance.
3. For each finding, decide: fix (legitimate issue), or no code change (invalid/outdated/preference/out of scope). Only implement changes you independently agree with.
4. Implement all required code changes first (minimal fixes only), then run relevant verification when practical.
5. Commit the fix set with meaningful commit boundaries by invoking the `commit` skill.
6. Push explicitly: run `git rev-parse --abbrev-ref --symbolic-full-name @{upstream}`; if it fails, run `git push --set-upstream origin HEAD`; otherwise run `git push`.
7. After the push, reply to every finding: for fixed ones, summarize what changed (with relevant files/functions/tests); for no-change ones, explain the code-level rationale with evidence. Where you accepted a finding but rejected the reviewer's reasoning, say so — the next PR gets the same advice otherwise.
8. Reply on the thread where there is one. For findings from a review body or issue comment there is no thread, so post one comment per PR covering every finding raised there, matching the reviewer's own numbering — one reply per finding spams a conversation with no threading to contain it.
9. Resolve a thread only after its reply is posted and you are confident it is fully handled (real fix or evidence-backed decline). Leave uncertain threads open. Findings outside a thread cannot be resolved, so the reply is the whole acknowledgement.
10. Do not leave any finding without a reply, and do not resolve just to clear the queue.

Done:
- Every outstanding finding has a direct reply grounded in code evidence, whichever object it arrived in.
- Required code changes are committed and pushed before posting replies.
- No thread is marked resolved without either a concrete fix or a clear evidence-backed rationale.

Reply:
Summarize each finding and whether it required a code change or rationale-only reply.

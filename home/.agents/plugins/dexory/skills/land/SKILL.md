---
name: land
description: User-invoked only via `/land` or `/dexory:land`. Do not trigger autonomously — no keyword or intent match should invoke this.
disable-model-invocation: true
---

# Land

Runs the full task-completion pipeline. Each stage runs in an isolated sub-agent and returns recommendations; you then apply them in this main context.

```
resolve scope → [ review-tests | react-best-practices? | simplify | finalise ]  (parallel)  →  apply  →  summarise
```

## Step 1 — Resolve the review scope

Resolve the scope **once**, up front, by running the bundled resolver. Pass the base the user gave `/land` (e.g. `/land staging` → `staging`); pass nothing if they didn't:

```bash
~/.agents/plugins/dexory/skills/land/scripts/resolve-scope.sh [base]
```

It prints `key=value` lines. Act on `mode`:

- **`uncommitted`** → scope is `git diff HEAD` plus the files in `untracked=` (they're not in the diff).
- **`branch`** → scope is `git diff <range>` using the printed `range=` (e.g. `origin/staging...HEAD`).
- **`ambiguous`** → the parent branch can't be inferred; ask the user which of `candidates=` to use **now**, before any stage runs, then re-run the resolver as `resolve-scope.sh <base>` with their answer.
- **`empty`** → the branch adds nothing over any base and the tree is clean; there's nothing to review. Report that and stop.

Announce the resolved scope, e.g. `**Scope: branch vs origin/staging** (git diff origin/staging...HEAD)`.

Also read `react=` from the resolver output. If `react=false`, Stage 2 (react-best-practices) is skipped entirely.

## Step 2 — Dispatch all applicable stages in parallel

Every stage runs in its own sub-agent — that's the point of `land`. Use the harness's sub-agent primitive (`Agent` in Claude Code, `~/.codex/agents/` in Codex CLI). **Do not invoke stage skills via the `Skill` tool directly from this context** — that loads the skill body inline and defeats the isolation.

The applicable stages are:

- **Stage 1**: `review-tests`
- **Stage 2**: `react-best-practices` — only if `react=true`. Skip entirely otherwise.
- **Stage 3**: `simplify`
- **Stage 4**: `finalise`

In a single message, dispatch a sub-agent per applicable stage. Announce the parallel dispatch, e.g. "**Dispatching review-tests, simplify, finalise in parallel** (react-best-practices skipped: no React in diff)."

### What every sub-agent prompt must contain

**Report, don't act.** This is the most important override. The stage skills all say "act, don't report" — you are explicitly reversing that for the `land` pipeline, because four sub-agents editing the same files in parallel would collide, and because you want to reconcile overlapping suggestions before applying. The sub-agent must **not** modify files. It returns a structured list of concrete, actionable recommendations — each with file path, line reference where applicable, and a clear description of the suggested change and why. If the stage skill would normally rewrite something, the sub-agent describes the rewrite instead of performing it. Say this in the prompt in words the sub-agent cannot misread.

**The scope directive, verbatim.** Sub-agents run in fresh contexts and can't see Step 1. Paste the resolved scope into every prompt so all stages review the same thing without re-detecting. Use one of these shapes:

Branch mode:
```
Scope: branch mode, base=<base>, range=<range>.
Use `git diff <range>` exactly. Do not re-run scope detection.
```

Uncommitted mode:
```
Scope: uncommitted. Review `git diff HEAD` plus these untracked files: <list>.
Do not re-run scope detection.
```

**Which stage skill to invoke.** Tell the sub-agent to invoke the named stage skill (`review-tests`, `react-best-practices`, `simplify`, or `finalise`) via its own `Skill` tool and follow its analysis end-to-end.

Wait for all sub-agents to return before moving on. Do not apply any changes until you have every report.

## Step 3 — Apply the recommendations

Once every sub-agent has returned, review the collected recommendations as a set and apply them yourself in this main context.

**Posture:** treat every suggestion as worth taking — nits, naming, small refactors included. The code is open now; get it right now. Effort isn't the constraint. Apply everything unless a suggestion is actually wrong or two reports genuinely conflict. Note any skips with the reason.

When reports overlap (e.g. simplify and review-tests both flag the same file), reconcile before editing — don't apply the same change twice.

## Step 4 — Summarise

Print a brief summary:

- Per stage: what it recommended (headline count is fine — e.g. "5 suggestions, 5 applied") and any skips with reasons.
- A short list of what actually changed in the working tree.
- Anything you deliberately did not apply, and why.
- Any hard failures from sub-agents surfaced clearly.

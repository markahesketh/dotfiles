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

Every stage runs in its own `reviewer` sub-agent — that's the point of `land`. Use the harness's sub-agent primitive (`Agent` in Claude Code, `spawn_agent` in Codex). The reviewer invokes the stage skill in its existing thread; the orchestrator, not the stage skill, owns isolation.

### Review model policy

`reviewer` is the shared review-calibre profile used by this pipeline and other review workflows. It deliberately does not inherit the parent session's model:

- **Claude Code:** the `reviewer` agent pins the rolling `opus` alias at `high` effort.
- **Codex:** the `reviewer` agent pins `gpt-5.6-sol` at `medium` reasoning.

Select the named agent for every stage; do not choose models stage by stage. The profile is a ceiling on review spend while preserving enough judgment for all four passes. If the named agent is unavailable, use explicit per-spawn values matching the policy above. If the harness cannot pin both model and effort, stop before dispatch and ask the user to reload or install the agent definition — never silently inherit an expensive parent model.

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

**Which stage skill to invoke.** Tell the sub-agent to invoke the named stage skill (`review-tests`, `react-best-practices`, `simplify`, or `finalise`) via its own Skill tool and follow its analysis end-to-end in the current reviewer thread. Stage skills do not choose their own isolation, so this does not create a wrapper agent.

If a stage skill requests nested delegation (currently `simplify` does), preserve that fan-out when the harness supports it. Use a purpose-built review agent when one is defined for a lens; otherwise use `reviewer` for every nested review so the model policy propagates. When the harness does not allow nested subagents, tell the stage agent to perform the lenses itself and return one combined report.

Wait for all sub-agents to return before moving on. Do not apply any changes until you have every report.

## Step 3 — Apply the recommendations

Once every sub-agent has returned, review the collected recommendations as a set and apply them yourself in this main context.

**You are the decision-maker, not a relay.** Each sub-agent saw only the diff. You know the task intent, what was tried and rejected along the way, and the conventions this change sits in — so a recommendation that looks obviously right to a fresh reviewer can still be wrong here, and only you can tell. Adjudicate every one before it lands.

Bias toward applying: nits, naming, and small refactors included. The code is open now, and volume of feedback is not a reason to start filtering. But reject on evidence where a finding earns it, and name the ground:

- **Wrong on the facts** — the claim doesn't hold when you check it: the helper it cites doesn't exist or doesn't do that, the "duplicate" asserts something different, the code it describes isn't what's there.
- **Contradicts a deliberate decision** taken in this session or visible in the history. Say what the decision was.
- **Violates a convention the sub-agent couldn't see** — established elsewhere in the codebase, or an explicit instruction from the user.
- **Changes behaviour**, where the stage that raised it is behaviour-preserving by mandate.
- **Conflicts with another report** — pick one and say which.

These are not grounds: "minor" / "a nit", "out of scope for this change", "would take a while", "the existing code reads fine", or bare disagreement with no check performed. If you can't name a ground, apply the finding.

**Verify before anything destructive.** A recommendation that deletes a test, removes a code path, or claims coverage already exists elsewhere is a factual claim — confirm it against the files first. A false positive there removes something whose absence you won't notice.

When reports overlap (e.g. simplify and review-tests both flag the same file), reconcile before editing — don't apply the same change twice.

**Verification is yours.** Every stage ran report-only, so none of them ran the build or the tests as its own skill would normally require. Once you've finished applying, run them and surface any failure in Step 4.

## Step 4 — Summarise

Print a brief summary:

- Per stage: what it recommended (headline count is fine — e.g. "5 suggestions, 5 applied") and any skips with reasons.
- A short list of what actually changed in the working tree.
- Anything you deliberately did not apply, and why.
- Any hard failures from sub-agents surfaced clearly.

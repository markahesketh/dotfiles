---
name: land
description: "Landing sequence — runs review-tests, finalise, simplify, and dexory:lint in order. Use when finishing a task and wanting to run the full quality pipeline: review and tighten the branch's tests, clean up code, simplify, and fix lint. Trigger phrases: land, landing sequence, finish up, wrap up, run the pipeline."
disable-model-invocation: true
---

# Land

Runs the full task completion pipeline in sequence: tests → react best practices (if applicable) → finalise → simplify → lint.

## Instructions

Run these skills in order, announcing the start and end of each stage clearly. Do not skip a stage if a previous one had warnings — only stop if a stage produces a hard failure that would block the next stage from running meaningfully.

### Stage 0 — Resolve review scope (do this first)

Resolve the scope **once**, up front, by running the bundled resolver. Pass the base the user gave `/land` (e.g. `/land staging` → `staging`); pass nothing if they didn't:

```bash
~/.agents/plugins/dexory/skills/land/scripts/resolve-scope.sh [base]
```

It prints `key=value` lines. Act on `mode`:

- **`uncommitted`** → scope is `git diff HEAD` plus the files in `untracked=` (they're not in the diff).
- **`branch`** → scope is `git diff <range>` using the printed `range=` (e.g. `origin/staging...HEAD`).
- **`ambiguous`** → the parent branch can't be inferred; ask the user which of `candidates=` to use **now**, before any stage runs, then re-run the resolver with that base.
- **`empty`** → the branch adds nothing over any base and the tree is clean; there's nothing to review. Report that and stop.

Announce the resolved scope, e.g. `**Scope: branch vs origin/staging** (git diff origin/staging...HEAD)`.

Hold the mode + range as the **scope directive**. The stages run in forked contexts and can't see this one, so pass the directive in each stage's Skill `args` and tell it to use that exactly and not re-detect. Keep the `react=` value for Stage 2. Lint is the exception — it always runs on the whole tree.

### Stage 1 — Review Tests

Announce: "**[1/5] Starting: review-tests**"

Use the Skill tool to invoke `review-tests`, passing the scope directive in `args` (e.g. "Scope: branch mode, base = origin/staging — review only `git diff origin/staging...HEAD`. Use this exactly; do not re-detect scope.").

When complete, announce: "**[1/5] Done: review-tests**"

---

### Stage 2 — React Best Practices (conditional)

This stage applies only if the scoped diff touches React. The resolver already computed this — use the `react=` value from Stage 0. (`react=true` → apply; `react=false` → skip.)

**If React code is present (`react=true`):**

Announce: "**[2/5] Starting: react-best-practices**"

Use the Skill tool to invoke `react-best-practices`, passing the scope directive in `args` and instructing it to apply only to the files in that scoped diff.

When complete, announce: "**[2/5] Done: react-best-practices**"

**If no React code is present:**

Announce: "**[2/5] Skipped: react-best-practices (no React code in diff)**"

---

### Stage 3 — Simplify

Announce: "**[3/5] Starting: simplify**"

Use the Skill tool to invoke `simplify`, passing the scope directive in `args` and instructing it to use that scope exactly and not re-detect.

When complete, announce: "**[3/5] Done: simplify**"

---

### Stage 4 — Finalise

Announce: "**[4/5] Starting: finalise**"

Use the Skill tool to invoke `finalise`, passing the scope directive in `args` and instructing it to use that scope exactly and not re-detect.

When complete, announce: "**[4/5] Done: finalise**"

---

### Stage 5 — Lint

Announce: "**[5/5] Starting: dexory:lint**"

Use the Skill tool to invoke `dexory:lint`. **Do not pass the scope directive** — lint runs on the whole tree by design.

When complete, announce: "**[5/5] Done: dexory:lint**"

---

### Final summary

After all stages, print a brief summary of what each stage did or changed. If any stage found nothing to do or was skipped, say so. If any stage failed, surface the error clearly.

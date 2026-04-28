---
name: land
description: "Landing sequence — runs add-tests, finalise, simplify, and dexory:lint in order. Use when finishing a task and wanting to run the full quality pipeline: add missing tests, clean up code, simplify, and fix lint. Trigger phrases: land, landing sequence, finish up, wrap up, run the pipeline."
disable-model-invocation: true
---

# Land

Runs the full task completion pipeline in sequence: tests → react best practices (if applicable) → finalise → simplify → lint.

## Instructions

Run these skills in order, announcing the start and end of each stage clearly. Do not skip a stage if a previous one had warnings — only stop if a stage produces a hard failure that would block the next stage from running meaningfully.

### Stage 1 — Add Tests

Announce: "**[1/5] Starting: add-tests**"

Use the Skill tool to invoke `add-tests`.

When complete, announce: "**[1/5] Done: add-tests**"

---

### Stage 2 — React Best Practices (conditional)

Before running this stage, check whether the current diff contains any React code. Run:

```
git diff HEAD
```

If the diff includes any `.tsx`, `.jsx` files, or imports of `react` in `.ts`/`.js` files, this stage applies. Otherwise skip it entirely.

**If React code is present:**

Announce: "**[2/5] Starting: react-best-practices**"

Use the Skill tool to invoke `react-best-practices`.

When complete, announce: "**[2/5] Done: react-best-practices**"

**If no React code is present:**

Announce: "**[2/5] Skipped: react-best-practices (no React code in diff)**"

---

### Stage 3 — Finalise

Announce: "**[3/5] Starting: finalise**"

Use the Skill tool to invoke `finalise`.

When complete, announce: "**[3/5] Done: finalise**"

---

### Stage 4 — Simplify

Announce: "**[4/5] Starting: simplify**"

Use the Skill tool to invoke `simplify`.

When complete, announce: "**[4/5] Done: simplify**"

---

### Stage 5 — Lint

Announce: "**[5/5] Starting: dexory:lint**"

Use the Skill tool to invoke `dexory:lint`.

When complete, announce: "**[5/5] Done: dexory:lint**"

---

### Final summary

After all stages, print a brief summary of what each stage did or changed. If any stage found nothing to do or was skipped, say so. If any stage failed, surface the error clearly.

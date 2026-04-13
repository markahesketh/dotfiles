---
name: dexory:land
description: Landing sequence — runs add-tests, finalise, simplify, and dexory:lint in order. Use when finishing a task and wanting to run the full quality pipeline: add missing tests, clean up code, simplify, and fix lint. Trigger phrases: land, landing sequence, finish up, wrap up, run the pipeline.
---

# Land

Runs the full task completion pipeline in sequence: tests → finalise → simplify → lint.

## Instructions

Run these four skills in order, announcing the start and end of each stage clearly. Do not skip a stage if a previous one had warnings — only stop if a stage produces a hard failure that would block the next stage from running meaningfully.

### Stage 1 — Add Tests

Announce: "**[1/4] Starting: add-tests**"

Use the Skill tool to invoke `add-tests`.

When complete, announce: "**[1/4] Done: add-tests**"

---

### Stage 2 — Finalise

Announce: "**[2/4] Starting: finalise**"

Use the Skill tool to invoke `finalise`.

When complete, announce: "**[2/4] Done: finalise**"

---

### Stage 3 — Simplify

Announce: "**[3/4] Starting: simplify**"

Use the Skill tool to invoke `simplify`.

When complete, announce: "**[3/4] Done: simplify**"

---

### Stage 4 — Lint

Announce: "**[4/4] Starting: dexory:lint**"

Use the Skill tool to invoke `dexory:lint`.

When complete, announce: "**[4/4] Done: dexory:lint**"

---

### Final summary

After all stages, print a brief summary of what each stage did or changed. If any stage found nothing to do, say so. If any stage failed, surface the error clearly.

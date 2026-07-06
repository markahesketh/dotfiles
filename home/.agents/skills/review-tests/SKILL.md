---
name: review-tests
description: Review the tests added on the current branch and fix them.
context: fork
model: opus
---

# Review Tests

Fresh-eyes pass over the tests in scope. Scope is decided by whoever invoked you: if a caller (e.g. the `land` skill, or the user's prompt) gave you a diff range or base branch, review exactly that (`git diff <range>`, or `git diff <base>...HEAD`). Otherwise default to the working-tree changes — `git diff HEAD` plus untracked files (`git ls-files --others --exclude-standard`); if that's empty, say so and ask for a base rather than auditing the whole suite. Either way, just the tests in that scope. **Act, don't report**: make the changes, then summarise. A bare "review the tests" still means *do the work*.

Read the impl too — you can't judge a test's level without knowing what it exercises. Match the project's frameworks and conventions.

Apply judgement, not a checklist. The non-obvious defaults:

- **Right level, and move down if not.** Each behaviour belongs at the lowest/cheapest level that still proves it: logic/validations → model/unit; HTTP/status/redirects/JSON → request/controller; only genuine browser/JS journeys → system/Cucumber. A browser test asserting what's really a validation is over-leveled — **rewrite it at the lower level, don't just delete it** (deleting loses coverage). Browser/e2e is slow and brittle; reserve it.
- **Cut overlap, keep complementary.** Same outcome of the same logic asserted at two levels → keep the lower, drop the higher. Keep a higher-level test only when it proves something distinct (wiring/integration that could break on its own). When you remove a Cucumber scenario, remove the now-orphaned step definitions too.
- **Fill real gaps only.** Add tests for uncovered core logic, failure/sad paths, and edges (nil, empty, boundary, permissions) — at the right level. Skip trivial getters, boilerplate, restated-implementation, duplicate coverage.
- **Names document behaviour + condition**, concisely. Rename vague/bloated ones.

Verify (run affected tests, or reason through if you can't), then report what you moved / removed / renamed / added.

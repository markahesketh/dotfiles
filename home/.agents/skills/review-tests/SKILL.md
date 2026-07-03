---
name: review-tests
description: Review the tests added on the current branch and fix them — move over-leveled tests down to the cheapest level that still proves the behaviour, remove coverage that overlaps across levels, tighten vague test names, and add any high-value tests that are missing. Use when the user asks to review tests or specs, check whether tests are at the right level, asks if a Cucumber/system test should be lower down, mentions a bloated or slow test suite, wants test coverage assessed, or says things like "review tests", "review specs", "are these tests in the right place", "lean test suite", "too many system tests", "test coverage", "missing tests".
context: fork
model: opus
---

# Review Tests

Fresh-eyes pass over the tests in scope. Check `git status --porcelain` first: if it reports staged, unstaged, or untracked changes, that's work in progress — scope to just that (`git diff HEAD`, plus any untracked files from the status output, since they won't show in the diff). If the tree is clean, there's nothing uncommitted to isolate, so review the whole branch instead (`git diff $(git merge-base HEAD origin/<default>)..HEAD`). Either way, just the tests in scope — don't audit the whole suite. **Act, don't report**: make the changes, then summarise. A bare "review the tests" still means *do the work*.

Read the impl too — you can't judge a test's level without knowing what it exercises. Match the project's frameworks and conventions.

Apply judgement, not a checklist. The non-obvious defaults:

- **Right level, and move down if not.** Each behaviour belongs at the lowest/cheapest level that still proves it: logic/validations → model/unit; HTTP/status/redirects/JSON → request/controller; only genuine browser/JS journeys → system/Cucumber. A browser test asserting what's really a validation is over-leveled — **rewrite it at the lower level, don't just delete it** (deleting loses coverage). Browser/e2e is slow and brittle; reserve it.
- **Cut overlap, keep complementary.** Same outcome of the same logic asserted at two levels → keep the lower, drop the higher. Keep a higher-level test only when it proves something distinct (wiring/integration that could break on its own). When you remove a Cucumber scenario, remove the now-orphaned step definitions too.
- **Fill real gaps only.** Add tests for uncovered core logic, failure/sad paths, and edges (nil, empty, boundary, permissions) — at the right level. Skip trivial getters, boilerplate, restated-implementation, duplicate coverage.
- **Names document behaviour + condition**, concisely. Rename vague/bloated ones.

Verify (run affected tests, or reason through if you can't), then report what you moved / removed / renamed / added.

---
name: tdd
description: Test-driven development with red-green-refactor loop. Use when user wants to build features or fix bugs using TDD, mentions "red-green-refactor", wants integration tests, or asks for test-first development.
---

# Test-Driven Development

## Philosophy

**Tests verify behavior through public interfaces, not implementation.** Code can change entirely; tests shouldn't. A good test reads like a specification — "user can checkout with valid cart" tells you what capability exists, and survives any refactor that keeps that capability.

Three kinds of tests:

- **Good** — exercises real code paths through the public interface. Describes _what_, not _how_.
- **Worthless** — restates the implementation (asserts the exact constants/branches just written). Passes when the code is wrong, fails when the code changes safely. Zero confidence.
- **Bad** — coupled to internals: mocks collaborators you own, tests private methods, asserts on call counts/order. Breaks on refactor even when behavior is unchanged.

The warning sign for bad tests: rename an internal method and the test fails though behavior didn't change.

See [tests.md](tests.md) for examples and [mocking.md](mocking.md) for where mocking belongs.

## Anti-Pattern: Horizontal Slices

**Don't write all the tests first, then all the implementation.** That's "horizontal slicing" — RED becomes "write every test", GREEN becomes "write all the code". It produces crap tests:

- Bulk tests describe _imagined_ behavior, not what the code actually does
- You test the _shape_ of things (data structures, signatures) instead of behavior
- They go insensitive to real changes — pass when behavior breaks, fail when it's fine
- You commit to test structure before you understand the implementation

Default to **vertical slices**: one test → just enough code → repeat, each test informed by what the last one taught you.

```
WRONG (horizontal):  RED: t1..t5   then   GREEN: impl1..impl5
RIGHT (vertical):    t1→impl1, t2→impl2, t3→impl3, ...
```

**The exception — atomic implementations.** Some code has no meaningful intermediate green state: a single regex, one formula, a pure lookup. There, the cases (full input, each component, malformed input) are facets of _one indivisible function_, not steps you build up. Writing those few tests together and implementing once is honest TDD — the slices genuinely don't exist. The test: are you specifying separate _behaviors_ (slice them) or _examples of one behavior_ (group them)? When in doubt, slice.

Either way, **don't fake the loop.** If you wrote tests together, say so in your cycle notes. A reconstructed "I did 10 red-green cycles" narrative over code that was written in one pass is worse than an honest "this was atomic, written together" — it hides what actually happened and trains the wrong reflex.

## Levels: Outside-In

Match the test to the level of behavior. An acceptance/feature test describes a user-visible capability; a unit test describes one object's behavior.

For acceptance-driven work, work **outside-in / double-loop**: write a failing acceptance test, then drop down to unit-level red-green to build each piece it needs, then return to green at the acceptance level. Don't write every unit test up front — let the failing acceptance test pull the next unit into existence.

## Workflow

### 1. Planning

Use the project's domain glossary so test names and interface vocabulary match the project's language; respect ADRs in the area you're touching.

Before writing code:

- [ ] Confirm with user what interface changes are needed
- [ ] Confirm which behaviors to test, and prioritize — you can't test everything
- [ ] Identify [deep modules](deep-modules.md): small interface, deep implementation, designed for testability
- [ ] List behaviors to test (not implementation steps)
- [ ] Get user approval on the plan

Ask: "What should the public interface look like? Which behaviors matter most?" Focus effort on critical paths and complex logic, not every edge case.

### 2. Tracer Bullet

Write ONE test that confirms ONE thing end-to-end:

```
RED:   test for first behavior → fails
GREEN: minimal code to pass → passes
```

This proves the path works.

### 3. Incremental Loop

For each remaining behavior: `RED → GREEN`, then repeat.

- One test at a time
- Only enough code to pass the current test
- Don't anticipate future tests
- Keep tests on observable behavior

### 4. Refactor

After GREEN, look for [refactor candidates](refactoring.md): duplication, modules to deepen, SOLID where natural, what the new code reveals about existing code. Run tests after each step.

**Never refactor while RED.** Get to GREEN first.

## Checklist Per Cycle

```
[ ] Test describes behavior, not implementation
[ ] Test uses the public interface only
[ ] Test would survive an internal refactor
[ ] Assertions prove feature behavior, not copied implementation values
[ ] Code is minimal for this test; nothing speculative added
```

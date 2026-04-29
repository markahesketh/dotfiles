---
name: lint
description: Run bin/lint --fix in DexoryView and fix any remaining issues until all linting passes. Use when linting, fixing lint errors, running rubocop, fixing TypeScript errors, fixing biome issues, or when the user says "fix lint" or "run lint" in the DexoryView project.
context: fork
model: sonnet
---

# Dexory Lint

Run `bin/lint --fix` and fix all remaining issues until every check passes.

## What bin/lint --fix runs

| Step | Command | Auto-fixes? |
|------|---------|-------------|
| Security audit | `bin/bundle-audit check --update` | No |
| Rails autoload | `bin/rails zeitwerk:check` | No |
| TypeScript types | `yarn lint:tsc` | No |
| Ruby linter | `bin/rubocop -A` | Yes |
| Biome formatter | `yarn format:fix` | Yes |
| Biome linter | `yarn lint:fix` | Yes |
| Security scanner | `bin/brakeman --exit-on-warn --exit-on-error --ensure-latest` | No |
| TODO notes check | `bin/rails notes` | No |

## Steps

1. Run `bin/lint --fix` and capture the full output
2. If all checks pass, report "Lint passed" and stop
3. If checks fail, identify which tool(s) reported errors
4. Fix remaining issues that were not auto-fixed:
   - **TypeScript errors** (`yarn lint:tsc`): Fix type errors, add missing types, correct type annotations
   - **Brakeman warnings**: Fix the flagged security issue in the Ruby code
   - **Bundle audit**: Inform the user — a gem version bump may be required
   - **Zeitwerk errors**: Fix autoload mismatches (file name must match constant name)
   - **TODO notes**: Inform the user — do not remove or resolve TODOs without their direction
5. Re-run `bin/lint --fix` to verify fixes
6. Repeat until all checks pass
7. Track attempts per issue — after 5 failed attempts on the same issue, ask the user for guidance
8. Provide a grouped summary of all fixes made

## Behaviour

- **Always use `--fix`**: Run `bin/lint --fix`, never plain `bin/lint` — this lets rubocop and biome auto-correct before any manual work is needed
- **Autonomous fixing**: Fix TypeScript, brakeman, and zeitwerk issues without asking
- **Bundle audit / TODO notes**: Surface these to the user rather than silently changing things — they may require decisions
- **No auto-commit**: Leave all changes unstaged for the user to review
- **Loop detection**: Track attempts per issue signature (file + line + error type); after 5 failed attempts, use AskUserQuestion

## Summary format

```
## Lint Fixes Summary

**Rubocop** (auto-fixed)
- 8 offences corrected across 3 files

**TypeScript errors (2 fixed)**
- Added return type to `handleSubmit` in app/javascript/components/Foo.tsx
- Added null guard in app/javascript/util/bar.ts

**Biome** (auto-fixed)
- Formatting corrected in 2 files
```

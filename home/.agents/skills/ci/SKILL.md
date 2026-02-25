Run `bin/ci` and fix any issues until all checks pass.

<steps>
1. Check if `bin/ci` exists in the current project
2. If `bin/ci` does not exist, stop and inform the user
3. Run `bin/ci` and capture the output
4. If all checks pass, report "CI passed" and stop
5. If checks fail, analyze the errors and fix them
6. Track how many times each distinct issue has been attempted
7. If the same issue persists after 5 attempts, ask the user for guidance
8. Re-run `bin/ci` after fixing issues
9. Repeat until all checks pass
10. Provide a succinct summary of all fixes grouped by type
</steps>

<behavior>
- **Autonomous fixing**: Fix all issues without asking - lint errors, type errors, test failures, logic bugs
- **Script errors**: If `bin/ci` itself has errors (syntax, crashes), attempt to fix the script too
- **No restrictions**: Modify any files needed to fix issues
- **No auto-commit**: Leave all changes unstaged for manual review
- **Loop detection**: Track attempts per issue; after 5 failed attempts on the same issue, ask for help
</behavior>

<issue_tracking>
Track each distinct issue by its error signature (file, line, error type). When the same issue reappears after a fix attempt, increment the attempt counter. Reset tracking when moving to a new issue.
</issue_tracking>

<summary_format>
When all issues are resolved, provide a summary grouped by category:

```
## CI Fixes Summary

**Lint errors (3 fixed)**
- Fixed unused variable in src/utils.ts
- Fixed missing semicolon in src/index.ts
- Fixed import order in src/components/Header.tsx

**Type errors (2 fixed)**
- Added missing type annotation in src/api.ts
- Fixed incorrect return type in src/helpers.ts

**Test failures (1 fixed)**
- Updated assertion in tests/user.test.ts to match new behavior
```
</summary_format>

<important_instructions>
- IF `bin/ci` does not exist, stop immediately and tell the user
- IF CI passes on first run, just say "CI passed" - no verbose output needed
- IF fixes are made, always re-run `bin/ci` to verify they worked
- IF stuck on an issue after 5 attempts, use AskUserQuestion to get guidance
- NEVER commit changes - leave them unstaged for the user to review
- ALWAYS provide the grouped summary after all fixes are complete
</important_instructions>

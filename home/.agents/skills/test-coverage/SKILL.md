---
name: test-coverage
description: Analyze code coverage and generate missing tests until coverage gaps are filled.
---

Analyze code coverage and generate missing tests until coverage gaps are filled.

<steps>
1. Detect the test framework:
   - Check Gemfile for `rspec-rails` or `minitest` gems
   - If Gemfile unavailable, check for `spec/` (RSpec) or `test/` (Minitest) directories
   - If both frameworks present, prefer RSpec
2. Locate coverage report:
   - Prefer `coverage/.resultset.json` (SimpleCov JSON format)
   - Fall back to `coverage/index.html` (SimpleCov HTML format)
   - If no coverage report exists, use file-based detection (compare source files to test files)
3. Parse coverage data:
   - Identify files with less than 80% coverage
   - Sort by lowest coverage percentage first
   - Exclude `vendor/`, `node_modules/`, and gem paths
   - Respect any exclusions in `.simplecov` config if present
4. For each uncovered file, generate appropriate tests:
   - `app/models/` -> model specs/tests
   - `app/controllers/` -> request specs/tests
   - `app/services/` -> service specs/tests
   - `lib/` -> lib specs/tests
5. If test file already exists, augment it with missing test cases for uncovered methods
6. Run the generated tests and fix any failures
7. Provide a summary of tests created and coverage improvements
</steps>

<framework_detection>
**RSpec indicators:**
- Gemfile contains `rspec-rails` or `rspec`
- `spec/` directory exists
- `spec/spec_helper.rb` or `spec/rails_helper.rb` present

**Minitest indicators:**
- Gemfile contains `minitest` (or default Rails without RSpec)
- `test/` directory exists
- `test/test_helper.rb` present
</framework_detection>

<test_generation>
**For RSpec projects:**
- Use the `rspec-tester` skill to generate specs
- Follow existing spec patterns in the project
- Use FactoryBot if available

**For Minitest projects:**
- Generate basic test scaffolds following Rails conventions
- Use fixtures or FactoryBot if present
- Follow existing test patterns in the project
</test_generation>

<coverage_parsing>
**JSON format (preferred):**
Parse `coverage/.resultset.json` to extract:
- File paths and their line coverage arrays
- Calculate percentage from covered/total lines

**HTML format (fallback):**
Parse `coverage/index.html` to extract:
- File list with coverage percentages
- Identify files below 80% threshold
</coverage_parsing>

<important_instructions>
- IF no test framework detected, stop and ask the user which framework to use
- IF RSpec detected, ALWAYS use the `rspec-tester` skill for generating specs
- IF coverage report missing, proceed with file-based detection (do not run tests to generate report)
- IF both RSpec and Minitest present, prefer RSpec
- ALWAYS run generated tests after creation and fix any failures
- ALWAYS exclude vendor code, node_modules, and gem paths from analysis
- NEVER generate tests for files already at or above 80% coverage
- NEVER skip augmenting existing test files - add missing test cases for uncovered methods
</important_instructions>

<summary_format>
After completion, provide a summary:

```
## Test Coverage Summary

**Tests generated:**
- Created spec/models/user_spec.rb (was 45% -> now 92%)
- Augmented spec/services/payment_service_spec.rb (was 62% -> now 88%)
- Created spec/lib/validators/email_validator_spec.rb (was 0% -> now 95%)

**Files skipped (above 80%):**
- app/models/post.rb (85%)
- app/services/notification_service.rb (91%)

**Test results:** All 12 new tests passing
```
</summary_format>

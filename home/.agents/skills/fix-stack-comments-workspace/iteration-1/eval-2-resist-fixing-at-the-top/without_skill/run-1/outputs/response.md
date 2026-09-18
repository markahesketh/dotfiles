# Review comments on the stack: plan

## First, a correction

PR 6117 has no review comments. It has one comment only: the CodeRabbit
"draft PR not reviewed" notice. There are no inline threads, no review
bodies and no human comments.

PR 6117 also has no code. Its three commits are `chore: carry the combined
branch for the QA review app` and two `chore: retrigger the QA review app
build`. All of them are empty. The branch is a merge of the layers below it.
Your own PR body says it is "for the review app rather than for merge".

So I cannot address comments on 6117. There is nothing there to change, and a
change made there would never reach staging.

The comments are on four **lower** PRs. jmlacroix posted them on 15 September,
after he re-ran the test-reliability reviewer from #6256 locally. He marks them
all as advisory: "nothing blocks".

| PR | Branch | Findings |
|----|--------|----------|
| 6112 | adapt-metrics-definitions | 5 |
| 6114 | adapt-task-parity | 1 |
| 6266 | adapt-last-scan-query | 2 |
| 6225 | adapt-correctness-tasks-filter | 1 |

PRs 6113, 6115, 6116 and 6117 have no findings.

## Attribution: the comments are already in the correct place

I checked each finding with `git blame` against the stack tip. Every finding
points at lines that the commit of that same PR introduced. Nobody posted a
comment on the wrong layer.

- `spec/factories/deployment.rb:48-50`, `spec/models/site_spec.rb:1729-1732`,
  `spec/queries/application_spec.rb:218-221`,
  `features/chatbot/scan_figure_parity.feature:1-10` and
  `chatbot_scan_figure_parity_steps.rb:5-6` come from `40efb02a0c` → **6112**.
- `tasks_dashboard_open_count` (steps file 194-196) comes from `5ece5d1064`
  → **6114**.
- `chatbot_last_scan_scope_steps.rb:78-81` and `scan_snapshot_spec.rb:275-279`
  come from `6366d53a12` → **6266**.
- `tasks_dashboard_row_count` (steps file 200-204) comes from `6d0f22a31a`
  → **6225**.

This matters because three different findings touch the same file
(`chatbot_scan_figure_parity_steps.rb`), but each one touches a different
method, and three different PRs own those methods. Do not put all three fixes
in one place.

## Why I will not fix these on 6117

6117 merges into nothing. If I put the fixes there:

- The fixes never reach staging. Each part below merges without them.
- The next `gh stack rebase` or re-merge of the lower branches rewrites or
  duplicates the work.
- The reviewer cannot see the answer to his comment. He reads 6112 and 6114.

The fix must go in the PR that owns the code. Then the cascade carries it up
into 6117 for free, and QA tests the fixed code on the same review app.

## Plan, per finding

Work bottom-up: 6112, then 6114, then 6266, then 6225. Then cascade the stack
so 6117 picks all of it up.

### PR 6112 (five findings)

1. **`spec/factories/deployment.rb` `:with_locations` is circular.** Correct.
   The base factory has `stopped_at { started_at + 10.minutes }` (line 13) and
   the trait overrides `started_at { stopped_at - 20.minutes }` (line 50). Each
   one asks for the other. Add `stopped_at { 10.minutes.ago }` inside the trait.
   Note: the bug is latent. All ten current callers pass `stopped_at`, so
   nothing fails today. Fix it anyway, because the factory is shared and the
   next caller pays for it.

2. **`spec/models/site_spec.rb` `Timecop.freeze` in an `around` hook.** Agreed
   on the action, but the stated reason is too strong. The hook does not bypass
   the suite clock; Timecop nests inside it and unwinds on block exit. So this
   is not a flake. It is a consistency point, and a fair one: the same file
   already uses `time:` metadata at lines 780 and 797, and
   `TestSuiteTimeMachine::RSpecHelpers` is included in `spec/rails_helper.rb:75`.
   Change to `describe "#scan_summary_snapshot", time: "2026-08-20 09:00 UTC"`
   and delete the hook.

3. **`spec/queries/application_spec.rb` hand-rolled SQL subscriber.** Correct.
   `queries_while` exists at `spec/support/sql_capture.rb:11`. Use it in the new
   test at line 218. Leave the identical older block at line 207 alone: it came
   from `196cce9678` and is not this PR's code.

4. **`stopped_at: 2.hours.ago` is yesterday just after site midnight.** Correct,
   and this one is a real flake. Cucumber runs on the real clock. Use
   `[fresh_site.now - 2.hours, fresh_site.now.beginning_of_day + 1.minute].max`.

5. **The Background logs in twice.** Correct. `I am logged in as a warehouse
   operator` creates a customer, a site and an operator, then logs in. `I am a
   Dexory employee` then logs out, creates a Dexory admin and logs in again.
   Take the second option he offers, not the first: drop the employee step and
   add `I have Adapt enabled`. The comment at
   `features/step_definitions/authentication_steps.rb:13-17` says Adapt
   scenarios run as a customer operator that holds both halves of the gate.
   That is the repo convention, and it keeps `@user` a member of `@site`.

   **This finding is coupled.** The Background belongs to 6112, but the
   scenarios that 6114, 6115, 6116 and 6225 add all inherit it. After the
   change, `@user` is an operator instead of a Dexory admin. Two things need a
   check on the upper layers, not on 6112:
   - The operator can open the site tasks page that `tasks_dashboard_open_count`
     visits.
   - The 6225 scenario "one of those tasks is assigned to me" still gives a
     match for `tasks_dashboard_row_count(assignee_name: [@user.name], ...)`.

### PR 6114 (one finding)

`tasks_dashboard_open_count` reads the badge too early. Correct.
`find_testid("status-filter-open")` returns as soon as the node exists, and the
node renders before the count arrives. Two changes:

- Replace the hand-built `visit` with `visit_tasks_list(fresh_site)`
  (`spec/support/system_navigation_helpers.rb:179`). It waits for the React
  mount and then for the skeleton to go. `SystemNavigationHelpers` is already
  in the cucumber World (`features/support/env.rb:97`).
- Turn the Then step into a retrying assertion instead of a scrape and compare:
  `expect(page).to have_css(testid_selector("status-filter-open"), text: /\b#{@chatbot_open_tasks}\b/)`.
  Keep the existing `expect(@chatbot_open_tasks).to be_positive`.

### PR 6266 (two findings)

1. **`run_finished_at` can order the two runs the wrong way.** Correct, and the
   worst of the nine. In the first minute of the site day, "just now"
   (`now - 1.minute`) falls into yesterday and "earlier today" is clamped to
   `beginning_of_day + 1.minute`, which is later. The newest run is then the
   wrong one, and the scenario asserts on scope. Apply his clamp to both
   branches.

2. **`scan_snapshot_spec.rb:275` assumes 10 and 20 minutes ago share a day.**
   Correct. The suite clock is pinned to the real boot time, so for the first
   20 minutes of the site day the two ad-hoc scans straddle midnight, the
   snapshot keeps one, and `contain_exactly` fails. Pin the context with
   `time: "2026-08-20 09:00 UTC"`, the way line 401 already does.

### PR 6225 (one finding)

`tasks_dashboard_row_count` should use the shared helper. The action is right,
but one part of his reason is wrong, so I will not repeat it back to him:
`wait_for_data_table_settled` (`spec/support/reliable_click.rb:39`) does wait
the skeleton out; it is not blind to the load. The real defects are the other
two he names:

- `all("[role='row']").size` on an empty table idles for the whole
  `wait: 20`, then returns 0 anyway.
- The URL is hand-built, so it skips the mount wait.

Replace the body with `visit_tasks_list(fresh_site, **filters)` then
`data_table_rows("tasks").size` (`spec/support/system_test_helpers.rb:207`).
`data_table_rows` also guards the phantom leading row that the skeleton
header causes.

## Tests to run

Bottom-up, after each PR's fix:

- 6112: `bin/rspec spec/models/site_spec.rb spec/queries/application_spec.rb` and
  `bundle exec cucumber --profile compact features/chatbot/scan_figure_parity.feature`.
  The factory change is broad, so also run the ten `:with_locations` callers:
  `bin/rspec spec/models/scan_snapshot_spec.rb spec/models/site_spec.rb`.
- 6114 and 6225: `bundle exec cucumber --profile compact features/chatbot/scan_figure_parity.feature`.
- 6266: `bin/rspec spec/models/scan_snapshot_spec.rb` and
  `bundle exec cucumber --profile compact features/chatbot/last_scan_scope.feature`.

For the two clock findings, run the affected files a second time with
`TEST_DATE_AND_TIME` set to a time just after site-local midnight. That proves
the fix, because the default real-world clock hides the bug.

Then cascade: rebase 6113 through 6117 on the fixed layers, and re-run the
combined QA review app build so QA tests the fixed code.

## Two things to decide

1. **Do these block anything?** jmlacroix says no, and all eight PRs are still
   drafts. Findings 6112.4, 6266.1 and 6266.2 are real clock flakes and are
   worth fixing before the parts merge. The other six are small. Tell me if you
   want the three flakes only, or all nine.

2. **Finding 6112.5 touches every layer above it.** Changing the Background is
   one line in 6112, but it changes the logged-in user for scenarios in four
   other PRs. If you want the smallest safe change now, I can do the other
   eight and hold 6112.5 until you want the full cascade.

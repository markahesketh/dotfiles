# Stack review state, and the plan to clear it

I read the stack and all of the review feedback. I made no changes. Here is the plan for your approval.

## The stack

Eight PRs, bottom to top:

| PR | Branch | Content |
|----|--------|---------|
| 6112 | adapt-metrics-definitions | metric definitions, base of the stack |
| 6113 | adapt-slotting-access | slotting grants, RLS allowlist + structure.sql |
| 6114 | adapt-task-parity | open-task counts |
| 6115 | adapt-consolidation-planner | Consolidation Planner figures |
| 6116 | adapt-obstruction-denominator | obstruction denominator |
| 6266 | adapt-last-scan-query | "the last scan" scope |
| 6225 | adapt-correctness-tasks-filter | filtered task questions |
| 6117 | adapt-data-correctness-qa | QA review app only, no code |

Each branch contains its parent. Only the bottom is stale: 6112 is 23 commits behind staging.

## The review feedback

There are no inline review threads and no submitted reviews on any of the eight PRs. All of the feedback is in four top-level comments from jmlacroix, dated 15 September. So there is nothing to resolve; the replies must be new top-level comments. The CodeRabbit comments are only the "draft PR not reviewed" notice.

Nine findings, all test reliability, all advisory. I checked each one against the source. All nine are correct about the code they describe. Each finding is also already on the PR that owns the code, so no finding must move to a different layer:

**PR 6112 (5 findings)**
1. `spec/factories/deployment.rb` - the new `:with_locations` trait sets `started_at { stopped_at - 20.minutes }`, and the base factory sets `stopped_at { started_at + 10.minutes }`. This is circular. Every current caller passes `stopped_at`, so the trait works today, but it breaks the first time somebody does not.
2. `spec/models/site_spec.rb` `#scan_summary_snapshot` - an `around { Timecop.freeze(...) }` hook. The file already uses the `time:` metadata form at line 780.
3. `spec/queries/application_spec.rb` - a hand-rolled `ActiveSupport::Notifications` subscription. `queries_while` in `spec/support/sql_capture.rb` does the same work and strips the SCHEMA and TRANSACTION noise.
4. `features/step_definitions/chatbot_scan_figure_parity_steps.rb` - "scanned today" uses `2.hours.ago`, which is yesterday for the first two hours after site midnight.
5. `features/chatbot/scan_figure_parity.feature` - the Background logs in twice. "I am a Dexory employee" logs out and creates a second user, so `@user` is a Dexory admin and `@site` stays the operator's site.

**PR 6114 (1 finding)**
6. `tasks_dashboard_open_count` reads the filter badge as soon as the node exists. It must use `visit_tasks_list` and a retrying assertion.

**PR 6266 (2 findings)**
7. `run_finished_at` - "just now" and "earlier today" can invert in the first minute of the site day.
8. `spec/models/scan_snapshot_spec.rb` - the "ad-hoc scans" example needs two times on the same day and does not pin the clock.

**PR 6225 (1 finding)**
9. `tasks_dashboard_row_count` - hand-built URL, `wait: 20`, and `wait_for_data_table_settled`, which does not see Inertia XHR. It must use `visit_tasks_list` and `data_table_rows("tasks")`.

## Two points where I disagree with the reviewer

- **Findings 4 and 7, the clamp to `beginning_of_day + 1.minute`.** This does not always give a past time. If the clock is 00:00:30, then `beginning_of_day + 1.minute` is 30 seconds in the future. The clamp moves the bug; it does not remove it. For finding 4 the correct clamp is `[fresh_site.now - 2.hours, fresh_site.now.beginning_of_day].max`, which is always today and never in the future.
- **Finding 7 cannot be fixed by a clamp at all.** The step needs two ordered times in the same site day. In a day that is 30 seconds old, no two such times exist. The only correct fix is to pin the clock. `features/step_definitions/task_manager_steps.rb:10` already does this with `Timecop.freeze(Time.current.midday)`, so the pattern has precedent. I will pin the scan-run setup the same way.

## Other things that block the merge, not from the reviews

- **6112 fails "Code owner review".** It touches `app/queries/application.rb`, which CODEOWNERS assigns to `@botsandus/applications` and `@alexspeller`. 6113 and 6225 touch `lib/chat_bot/rls_setup.rb`, which needs `@jmlacroix` or `@alexspeller`. You are the author, so you cannot approve these. No reviewer is requested on any PR yet.
- **6114 CI has one failure:** `spec/system/virtual_environment/item_analytics_spec.rb:190`, "Unable to find link or button Export", 58 seconds. The stack does not touch that file. This is an unrelated flake. It needs a re-run, not a fix.
- **6116 CI is not really red.** Its "Test Ruby (17, 34)" node was cancelled, which made the build-success gate fail. A re-run clears it.
- **6115 shows CONFLICTING on GitHub, but the data is stale.** A local test merge into its base is clean. Re-submitting after the cascade clears the flag.
- **One real rebase conflict.** Staging PR #6314 rewrote `app/services/chat_bot/skills/space-utilisation.md`, and 6115 rewrites the same two sections. The conflict starts at 6115; 6112, 6113 and 6114 replay clean, and the layers above 6115 carry the resolution forward. The resolution is semantic: keep staging's new "When `consolidatable_fields` is empty" section, and put 6115's Planner content around it, with the empty-overlay sentence pointing at `site.consolidation_planner_available?`.
- **`db/structure.sql`.** 6113 adds an RLS grant migration and the dump. Staging added eight migrations since the merge base. The dump must be regenerated after the rebase, not merged by hand.
- **All eight PRs are drafts.** They must be marked ready before they can merge.
- **6117 holds no code.** Do not merge it. It is the QA review app branch. Rebuild its review app after the cascade, then close it.

## The order of work

1. Fix the five findings on **6112** at that layer, in one commit. Include the trait default, the `time:` metadata, `queries_while`, the clamped "scanned today" time, and the Background with the employee step dropped and "I have Adapt enabled" added.
2. Fix finding 6 on **6114** at that layer.
3. Fix findings 7 and 8 on **6266** at that layer. Pin the clock for the scan-run step.
4. Fix finding 9 on **6225** at that layer.
5. Run the touched tests at each layer before I move up: `spec/factories` callers, `site_spec.rb`, `application_spec.rb`, `scan_snapshot_spec.rb`, and the two cucumber features with `--profile compact`.
6. Run `bin/dv ai-review-matches`, read the matched reviewers, and revise. Then run `bin/lint`.
7. Cascade the whole stack onto staging, bottom up, in one pass. Resolve the `space-utilisation.md` conflict once at 6115, as described above.
8. Regenerate `db/structure.sql` after the rebase and commit it at 6113, where the migration lives.
9. Re-run the tests at the layers the rebase moved, then submit the stack.
10. Re-run the failed CI jobs on 6114 and 6116 and confirm every PR is green.
11. Post one reply per PR to jmlacroix's comment, item by item, saying what I changed, and saying plainly where I did something different from the advice and why. There are no threads to resolve.
12. Request the code owner reviews: `@botsandus/applications` or `@alexspeller` for 6112 and 6113, and `@jmlacroix` or `@alexspeller` for 6113 and 6225.
13. Mark 6112 to 6225 ready for review. Rebuild the 6117 review app for QA, and leave 6117 out of the merge.

Steps 11 to 13 need the code owner approvals, which I cannot give. So the stack will be ready to merge only after those approvals land.

I stopped here, as agreed. Tell me to go and I will start at step 1.

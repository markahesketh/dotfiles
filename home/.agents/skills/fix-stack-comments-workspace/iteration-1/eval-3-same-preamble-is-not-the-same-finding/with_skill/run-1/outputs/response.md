# Not one fix. Two different findings.

You are correct about the reviewer and the wording of the first paragraph. You are not correct that this is one fix.

Both comments come from `jmlacroix`. Both start with the same **Test-reliability to-do** preamble, word for word. That paragraph is boilerplate. The reviewer put it at the top of each comment to say where the findings came from and that nothing blocks the merge. The finding itself is the paragraph below it, and the two paragraphs are different.

Both findings point at the same file, `features/step_definitions/chatbot_scan_figure_parity_steps.rb`, but at different helper methods:

| | #6114 | #6225 |
|---|---|---|
| Helper | `tasks_dashboard_open_count` | `tasks_dashboard_row_count(**filters)` |
| Reads | the `status-filter-open` badge text | the rows in the tasks data table |
| Problem | it scrapes the badge as soon as the node exists | hand-built URL, `wait: 20`, `wait_for_data_table_settled`, then `all("[role='row']").size` |
| Fix asked for | `visit_tasks_list(fresh_site)` **and** make the Then step a retrying assertion | `visit_tasks_list(fresh_site, **filters)` then `data_table_rows("tasks").size` |

The two helpers also belong to different layers of the stack. I confirmed this with the pickaxe:

- `tasks_dashboard_open_count` came in with `5ece5d1` — "count open tasks the way the tasks dashboard counts them" — which is **#6114**.
- `tasks_dashboard_row_count` came in with `6d0f22a` — "answer filtered and single-task questions from the tasks dashboard's query" — which is **#6225**.

So each comment sits on the PR that owns its code. No fix must move down the stack.

## The fixes are not interchangeable

This is the part that matters if you want to make one change for both. The recommended replacement, `visit_tasks_list`, calls `wait_for_data_table_settled`, which waits for the data-table skeleton to go away. That is enough for the #6225 row count, because the rows are in that table.

It is **not** enough for the #6114 badge count. The badge number comes from the `stats` Inertia prop, and `TasksController` declares that prop as `defer: true` (`app/controllers/tasks_controller.rb:60`). The page therefore paints the filter badge before the count arrives. The data table can be settled while the badge still shows the old number. Only the retrying assertion the reviewer asks for closes that hole:

```ruby
expect(page).to have_css(testid_selector("status-filter-open"), text: /\b#{@chatbot_open_tasks}\b/)
```

A single shared change would fix #6225 and leave #6114 flaky.

## I checked that the suggested helpers exist

- `visit_tasks_list(site, **params)` — `spec/support/system_navigation_helpers.rb:180`. In the cucumber World (`features/support/env.rb:97`).
- `data_table_rows(id)` — `spec/support/system_test_helpers.rb:207`. In the World (`features/support/env.rb:99`). It waits for the skeleton to go before it reads.
- `wait_for_data_table_settled` — `spec/support/reliable_click.rb:39`. The reviewer is right about it: it polls `window.turboRequestCount`, which counts `fetch` only.

## Plan

Two fixes, one for each PR. Each fix goes in the PR that owns the code, so nothing moves across layers.

**#6114 — `markahesketh/adapt-task-parity` — accept**
1. Change `tasks_dashboard_open_count` to use `visit_tasks_list(fresh_site)` in place of the hand-built `visit`.
2. Change the Then step at line 44 to the retrying `have_css` assertion, and keep the `be_positive` check.

**#6225 — `markahesketh/adapt-correctness-tasks-filter` — accept**
1. Replace the body of `tasks_dashboard_row_count(**filters)` with `visit_tasks_list(fresh_site, **filters)` then `data_table_rows("tasks").size`.
2. Both call sites keep their signature, so lines 119 and 145 do not change.

**Then, in this order**
1. Reply once on #6114 and once on #6225. These findings are plain PR comments, so there is no thread and no resolve button. The reply is the whole acknowledgement.
2. Cascade the stack one time with `gh stack rebase`, then `gh stack submit --auto`. Both fixes are near the top of the stack, so I expect few conflicts.

## Also outstanding, not part of this

The collector found 7 more findings from the same reviewer, in the same **Test-reliability to-do** form. They are on other layers:

- **#6112** — 5 findings: the `:with_locations` deployment factory, `site_spec.rb` `#scan_summary_snapshot`, `application_spec.rb` "sends one statement per...", `chatbot_scan_figure_parity_steps.rb`, and the `scan_figure_parity.feature` Background.
- **#6266** — 2 findings: `chatbot_last_scan_scope_steps.rb` and `scan_snapshot_spec.rb` "keeps the newest day...".

Tell me if you want these in the same round. If we do them together, we cascade once for all nine and save a rebase.

Nothing is changed yet. Say the word and I will start.

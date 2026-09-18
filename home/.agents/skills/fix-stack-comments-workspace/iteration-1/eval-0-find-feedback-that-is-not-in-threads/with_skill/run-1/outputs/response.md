# Review feedback on stack #6267 — plan before changes

## Where the feedback is

The stack has 8 PRs. Bottom to top: **6112, 6113, 6114, 6115, 6116, 6266, 6225, 6117**.

There are **no inline review threads and no reviews at all** on any of the 8 PRs. I
checked each PR with the API: 0 review comments, 0 reviews. All of the feedback is in
**4 plain PR comments** from `jmlacroix`, on 6112, 6114, 6266 and 6225. Each comment
holds 1 to 5 separate findings. That gives **9 findings**.

Two results follow from this:

- `gh pr view` shows these comments as conversation, not as review threads. GitHub
  cannot resolve them. A reply is the only acknowledgement possible.
- 6113, 6115, 6116 and 6117 have **no work to do**. Their only comment is the
  CodeRabbit "Draft PR not reviewed" notice, which is boilerplate on all 8 PRs.

The warning symbol on 6112 is the `Code owner review` gate, not a test failure. No
action.

## Attribution

I confirmed each owner with `git log -S` and commit-to-branch checks. Commit map:
`40efb02`+`46c7aff` = 6112, `5ece5d1` = 6114, `e942cf2`+`e8f017d` = 6116,
`6366d53` = 6266, `6d0f22a` = 6225.

Every finding is owned by the PR it was raised on. That is unusual for a stack, and it
holds here for one reason: `features/step_definitions/chatbot_scan_figure_parity_steps.rb`
is created in 6112 and then extended in 6114, 6116, 6266 and 6225, and each reviewer
comment names the helper its own layer added.

| # | Raised on | Owns | Subject | Decision | Lands in |
|---|---|---|---|---|---|
| 1 | 6112 | 6112 | `spec/factories/deployment.rb` — circular `started_at`/`stopped_at` | Accept | 6112 |
| 2 | 6112 | 6112 | `spec/models/site_spec.rb:1732` — `Timecop.freeze` in an `around` | Accept | 6112 |
| 3 | 6112 | 6112 | `spec/queries/application_spec.rb:218` — hand-rolled SQL subscriber | Accept, and see push-back B | 6112 |
| 4 | 6112 | 6112 | parity steps line 6 — `stopped_at: 2.hours.ago` breaks after midnight | Accept the problem, change the fix — push-back A | 6112 |
| 5 | 6112 | 6112 | `features/chatbot/scan_figure_parity.feature` — two logins in the Background | Accept, with a choice to make — see D | 6112 |
| 6 | 6114 | 6114 | parity steps 194-197 — `tasks_dashboard_open_count` reads the badge too early | Accept | 6114 |
| 7 | 6266 | 6266 | `chatbot_last_scan_scope_steps.rb:78` — `run_finished_at` inverts after midnight | Accept the problem, change the fix — push-back A | 6266 |
| 8 | 6266 | 6266 | `spec/models/scan_snapshot_spec.rb:275` — 10 and 20 minutes ago can split a day | Accept | 6266 |
| 9 | 6225 | 6225 | parity steps 200-205 — `tasks_dashboard_row_count` scrapes rows | Accept, reason corrected — see C | 6225 |

No finding asks for a stack restructure. No finding belongs to `staging`. No finding is
duplicated across layers.

## What I checked against the code

The reviewer is accurate. Every helper he tells us to use exists, at the line he gives:

- `visit_tasks_list` — `spec/support/system_navigation_helpers.rb:180`. It waits for the
  React mount, then calls `wait_for_data_table_settled`.
- `data_table_rows` — `spec/support/system_test_helpers.rb:207`. Its own comment explains
  the phantom first row that the current code hits.
- `queries_while` — `spec/support/sql_capture.rb:11`. It drops SCHEMA and TRANSACTION
  noise. `RSpec.configure` includes it for all specs.
- Both system helper modules are in the cucumber World — `features/support/env.rb:97`
  and `:99`.
- `time:` metadata is the repo convention. `site_spec.rb` uses it 3 times and Timecop
  once. `scan_snapshot_spec.rb` uses the exact form `time: "2025-11-30 22:00 UTC"`.

Two corrections of detail:

- Finding 8 cites `scan_snapshot_spec.rb:339` as the precedent. On this branch line 339
  is a `create` call. 339 is the line in `staging`. The precedent itself is real, at
  lines 401 and 423 on the branch.
- Finding 1 is latent, not live. All 4 current callers of `:with_locations` pass
  `stopped_at:`, so nothing fails today. The next caller that does not pass it gets
  infinite recursion. The fix is one line. Do it.

## Push-backs

**A. The suggested clamp does not do what it claims (findings 4 and 7).**

The reviewer asks for `[fresh_site.now - 2.hours, fresh_site.now.beginning_of_day +
1.minute].max`, and says this is "always today and always in the past". It is not always
in the past. At 00:00:30 site time, `beginning_of_day + 1.minute` is 30 seconds in the
future. The same applies to the `+ 2.minutes` clamp in finding 7. The clamp fails inside
the same window it is written for.

The problem he identifies is real. The scan times must share one site-local day, and
their order must be fixed. The repo already solves this a better way:
`features/step_definitions/task_manager_steps.rb:10` registers a `@frozen_clock` tag that
freezes the clock at midday, for this exact day-boundary reason. Cucumber hooks are
global, so the tag works on any feature.

I propose we tag `features/chatbot/scan_figure_parity.feature` and the last-scan feature
with `@frozen_clock` and keep the relative times as they are. That removes the whole class
of midnight failure in both layers with one line each, and it needs no arithmetic. Say if
you prefer the clamps and I will write them instead, with `beginning_of_day` and no offset
so they stay in the past.

**B. Finding 3 leaves its twin in place.**

`application_spec.rb` has the same hand-rolled `ActiveSupport::Notifications.subscribed`
block twice: at line 204 ("applies the settings before the wrapped statement") and at
line 218, which is the one he names. The same commit added both. I recommend we convert
both to `queries_while`, or neither. Confirm, because this goes past the letter of the
finding.

**C. Finding 9 is right, but not for the stated reason.**

He says `all("[role='row']").size` "idles the full timeout when there are no rows". As I
read Capybara, `all` with no count option accepts zero matches and returns at once, so
the fault is the opposite: the read is premature, not slow. The fix he asks for is still
the correct one, because `data_table_rows` waits the skeleton out and avoids the phantom
leading row. He is also slightly unfair to `wait_for_data_table_settled`, which does wait
for skeleton absence (`spec/support/reliable_click.rb:41`); only its
`wait_for_no_active_turbo_requests` half is blind to Inertia. I will make the change and
say this in the reply.

**D. Finding 5 needs a decision from you.**

The Background runs `I am logged in as a warehouse operator`, then `I am a Dexory
employee`. The second step logs out and creates a new admin user, so the operator is
discarded and the scenario logs in twice. Two options, and they are not equal:

- **Dexory employee alone** — the user is staff and is not a member of the site.
- **Operator plus `I have Adapt enabled`** — the user is a member of the site.

I recommend the second. The comment at `features/step_definitions/authentication_steps.rb:13`
says Adapt scenarios run as a customer operator holding both halves of the gate, and the
task scenarios filter the dashboard by `@user.name` as an assignee, which is more
representative for a site member.

Note the risk. The Background is 6112's, but 6114, 6116, 6266 and 6225 all add scenarios
to that same feature and inherit it. A fix in 6112 must be verified by running the whole
feature at the top of the stack, not in 6112 alone.

## How I would do the work

1. One agent per owning PR: 6112 (5 findings), 6114 (1), 6266 (2), 6225 (1). Each gets
   its own worktree. No agent runs `gh stack rebase`, `sync`, `push` or `submit`.
2. Findings 4, 6 and 9 all touch
   `features/step_definitions/chatbot_scan_figure_parity_steps.rb` at three different
   layers: line 6 in 6112, lines 194-197 in 6114, lines 200-205 in 6225. Expect conflicts
   in this file during the cascade. Keep the lower layer's version.
3. Reply before the cascade: one comment per PR, numbered to match his own list, on 6112,
   6114, 6266 and 6225. There is nothing to resolve, because none of the feedback is in a
   thread.
4. Cascade once, at the end: `gh stack rebase`, then `gh stack submit --auto`.
5. Verification: `bin/rspec` on the 3 touched spec files, and
   `bundle exec cucumber --profile compact` on both chatbot features, run at the top of
   the stack so 6112's Background change is tested against every scenario that inherits
   it.

Nothing is changed yet. Confirm the plan, and tell me your answers on push-backs A, B
and D.

# Review feedback on stack #6267 — what to do, and where

## Where the feedback is

Stack #6267 has 8 PRs. Four of them have feedback. All of the feedback is in
**plain PR comments**, not in review threads. I found:

- 0 inline review threads on any of the 8 PRs.
- 0 review bodies on any of the 8 PRs.
- 8 CodeRabbit comments. All say only "Draft PR not reviewed". They need no action.
- 4 comments from `jmlacroix`, posted 15 Sep 2026, one on each of four PRs.
  They hold 9 findings in total.

The author says the findings are advisory and that nothing blocks. The findings
come from re-running the test-reliability reviewer of PR #6256 by hand. They are
all about test reliability. No finding changes product behaviour.

| PR | Title (short) | Findings |
|---|---|---|
| 6112 | Adapt metric definitions | 5 |
| 6113 | Slotting access | 0 |
| 6114 | Task parity | 1 |
| 6115 | Consolidation planner | 0 |
| 6116 | Obstruction denominator | 0 |
| 6266 | Last-scan query | 2 |
| 6225 | Tasks filter | 1 |
| 6117 | QA review app | 0 |

## Ownership: every finding belongs to the PR it was posted on

I diffed each branch against its own base and traced each named file, method and
example. Each of the 9 findings touches code that the PR it sits on introduced.
No finding must move down or up the stack. This is worth saying, because three
findings name the same file (`chatbot_scan_figure_parity_steps.rb`) but different
helpers, and two name the same file (`scan_snapshot_spec.rb`) that two PRs touch:

- `tasks_dashboard_open_count` first appears on 6114. The comment is on 6114.
- `tasks_dashboard_row_count` first appears on 6225. The comment is on 6225.
- The `"keeps the newest day's ad-hoc scans..."` example first appears on 6266.
  The comment is on 6266.

## PR 6112 — 5 items

**Item 1. Circular factory default.** `spec/factories/deployment.rb:49`.
The base factory sets `started_at { 20.minutes.ago }` and
`stopped_at { started_at + 10.minutes }`. The `:with_locations` trait then
overrides `started_at { stopped_at - 20.minutes }`. The two definitions now point
at each other. **Confirmed.** Every current caller passes `stopped_at`, so nothing
fails today. The trait is a trap for the next caller.
*Action*: give the trait its own `stopped_at` default, for example
`stopped_at { 10.minutes.ago }`.
*Priority*: medium. Cheap, and it removes a trap.

**Item 2. `Timecop` in an `around` hook.** `spec/models/site_spec.rb:1732`.
The `#scan_summary_snapshot` block uses
`around { |example| Timecop.freeze(...) { example.run } }`.
**Confirmed.** `spec/rails_helper.rb:19` pins the suite clock with
`TestSuiteTimeMachine.pretend_it_is(ENV["TEST_DATE_AND_TIME"])`, and line 75
includes the time-machine RSpec helpers. A raw `Timecop.freeze` goes around that
control.
*Action*: replace the hook with the `time:` metadata form,
`describe "#scan_summary_snapshot", time: "2026-08-20 09:00 UTC" do`. The same
file already does this at line 780.
*Priority*: low. This is house style, not a flake.

**Item 3. Hand-rolled SQL capture.** `spec/queries/application_spec.rb:216-226`.
The example "sends one statement per setting rather than joining them" builds its
own `ActiveSupport::Notifications.subscribed(...)` block.
**Confirmed**, and the house helper exists: `queries_while` in
`spec/support/sql_capture.rb:11`, included for all specs. It also drops `SCHEMA`
and `TRANSACTION` noise, which the hand-rolled version keeps.
*Action*: `statements = queries_while { described_class.with_session_settings([...]) { Site.count } }`.
*Priority*: low. Behaviour does not change; the example gets shorter.

**Item 4. "Scanned today" can be yesterday.**
`features/step_definitions/chatbot_scan_figure_parity_steps.rb:6-8`.
The step passes `stopped_at: 2.hours.ago`. Cucumber runs on the real clock. For
the first two hours after site-local midnight, that time is yesterday, so the
scenario counts a different set of scans than it means to.
**Confirmed.** See "Where I disagree" below — I will not use the exact fix the
comment proposes.
*Priority*: medium. This is a real flake, in a 2-hour window each day.

**Item 5. The Background logs in twice.**
`features/chatbot/scan_figure_parity.feature:21-22`.
The Background runs `Given I am logged in as a warehouse operator` and then
`And I am a Dexory employee`. **Confirmed.** Both steps call `log_out`, create a
new user, and call `log_in_as`. The second step also replaces `@user` with a
Dexory admin who is *not* a member of `@site`. The comment in
`features/step_definitions/authentication_steps.rb:13-18` states the wanted
pattern: Adapt scenarios run as a customer operator that holds both halves of the
gate. `features/chatbot/conversation.feature:6-9` already uses that pattern.
*Action*: drop `And I am a Dexory employee` and add `And I have Adapt enabled`.
*Priority*: medium. It halves the Background cost of every scenario in the file,
and it removes one browser login per scenario.
*Take care*: this feature file also holds scenarios added by 6114, 6116 and 6225.
The change is in 6112, so all four PRs must run the file again after the cascade.

## PR 6114 — 1 item

**Item 6. The open-task badge is scraped before it settles.**
`features/step_definitions/chatbot_scan_figure_parity_steps.rb:196-199`
(`tasks_dashboard_open_count`). The helper calls `visit`, then
`Integer(find_testid("status-filter-open").text[/\d+/])`. `find` waits for the
node, not for the count in it.
**Confirmed**, and both replacements exist:
`visit_tasks_list` (`spec/support/system_navigation_helpers.rb:180`) waits for the
table to mount and then waits the skeleton out, and it is in the Cucumber World
(`features/support/env.rb:97`).
*Action*: two changes.
1. In the helper, use `visit_tasks_list(fresh_site)`.
2. Turn the `Then` step into a retrying assertion, not a scrape-and-compare:
   `expect(page).to have_css(testid_selector("status-filter-open"), text: /\b#{@chatbot_open_tasks}\b/)`.
*Priority*: high for this set. It is the one item that removes a read of a value
that is still loading.

## PR 6266 — 2 items

**Item 7. Midnight breaks the run ordering.**
`features/step_definitions/chatbot_last_scan_scope_steps.rb:79-83`
(`run_finished_at`). "just now" is `now - 1.minute`; "earlier today" is
`[now - 6.hours, beginning_of_day + 1.minute].max`. In the first minute after
site-local midnight, "just now" falls on yesterday and "earlier today" falls
*after* it, so the wrong run is the newest one.
**Confirmed.** The helper's own comment claims the opposite, so the comment is
also wrong and must change with the code.
*Action*: see "Where I disagree". The finding is right; the proposed fix is not.
*Priority*: medium.

**Item 8. Two times assumed to share a day.**
`spec/models/scan_snapshot_spec.rb:275-282`, the example "keeps the newest day's
ad-hoc scans when the newest scan had no run". It uses `10.minutes.ago` and
`20.minutes.ago` and expects one shared scan day. Right after midnight they fall
on two days. **Confirmed.**
*Action*: pin the example clock with `time:` metadata, as the comment says.
*Note*: the comment points at `scan_snapshot_spec.rb:339` as the in-file example.
That line number is wrong. The real examples are at lines 401 and 423.
*Priority*: medium.

## PR 6225 — 1 item

**Item 9. Hand-built tasks URL and row scrape.**
`features/step_definitions/chatbot_scan_figure_parity_steps.rb:202-207`
(`tasks_dashboard_row_count`). It builds the URL by hand, uses `find(..., wait: 20)`,
then `wait_for_data_table_settled`, then `all("[role='row']").size`.
**Confirmed in part.** `wait_for_data_table_settled`
(`spec/support/reliable_click.rb:39`) checks Turbo requests and skeleton absence,
so it is a weak signal for an Inertia page. `data_table_rows`
(`spec/support/system_test_helpers.rb:207`) waits the skeleton testid out, reads
under one `synchronize`, and returns body rows only, so `.size` is exact.
*Action*: replace the body with `visit_tasks_list(fresh_site, **filters)` and
`data_table_rows("tasks").size`.
*Take care*: the caller at line 129 ("the task as open") runs
`within_testid("data_table_body") { ... }` straight after this helper and depends
on the page it left behind. `visit_tasks_list` leaves the same page, so that still
works, but I will run the scenario to confirm.
*Priority*: medium.

## Where I disagree

**1. The proposed midnight clamps can hide the data (items 4 and 7).**
The comment proposes `beginning_of_day + 1.minute` and
`beginning_of_day + 2.minutes` as floors. In the first minutes after site-local
midnight those times are in the **future**. `ScanSnapshot#initialize` caps its
window with `@up_to_datetime = [site.now, @up_to_datetime].min`
(`app/models/scan_snapshot.rb:11`). A scan with a future `stopped_at` therefore
falls outside every snapshot. The proposed fix turns a rare ordering flake into a
rare no-data flake. It is smaller, but it is a worse failure, because it reads as
a product fault.

I propose instead that both helpers put their times inside the part of the day
that has already passed. This is always today, always in the past, and always
ordered, whatever the clock says:

```ruby
def run_finished_at(when_ran)
  day_start = fresh_site.now.beginning_of_day
  elapsed = fresh_site.now - day_start
  case when_ran
  when "just now" then day_start + (elapsed * 2 / 3)
  when "earlier today" then day_start + (elapsed / 3)
  else when_ran[/\d+/].to_i.hours.ago
  end
end
```

The same shape fixes item 4: `stopped_at: day_start + (elapsed / 2)`.

The two fixes must have the same shape, because they have the same cause, but
they go in two different PRs (6112 and 6266). I will write the same helper in
both, not share it, because sharing it would put 6266's helper into 6112.

**2. One claim in item 9 is too strong.** The comment says
`all("[role='row']").size` "idles the full timeout when there are no rows".
Capybara's `all` does not wait unless you give it a count option, so it returns
at once. The rest of item 9 holds, and the fix is still worth making, but not for
that reason.

**3. One line reference in item 8 is wrong** (`:339`, should be `:401` or `:423`).
Small, but I will not quote it back.

## Order of work

Work from the bottom of the stack up, so each rebase carries the fix below it:

1. **6112** — items 1, 2, 3, 4, 5.
2. **6114** — item 6.
3. **6266** — items 7, 8.
4. **6225** — item 9.
5. Cascade: `gh stack rebase`, then `gh stack submit`. 6113, 6115, 6116 and 6117
   carry no fix but must all rebase, because 6112 changes a feature file and a
   factory that the layers above use.
6. Reply to each of the four comments with what I did and what I did not do, and
   say why for items 4, 7, 8 and 9.

## How I will check the work

```
bin/rspec spec/models/site_spec.rb spec/queries/application_spec.rb spec/models/scan_snapshot_spec.rb
bundle exec cucumber --profile compact features/chatbot/scan_figure_parity.feature
bundle exec cucumber --profile compact features/chatbot/last_scan_scope.feature
bin/lint
```

The midnight window is the one thing these runs cannot prove, because Cucumber
runs on the real clock. For items 4 and 7 the proof is by reading the code: the
proposed times are a fraction of the elapsed part of the site's day, so they
cannot leave the day and cannot reach the future.

## What I have not done

Nothing is changed yet. I have not edited a file, posted a reply, resolved a
thread, rebased, or moved off `staging`. Tell me to start, and say if you want
all four PRs or only some of them.

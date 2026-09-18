# Review comments on stack #6267

## First: #6117 has no review comments

I must correct the premise before I show a plan.

**#6117 has no review findings.** It has one comment. A bot (`coderabbitai`) wrote it, and
it is a 684-character auto-summary stub. #6117 has zero reviews and zero human comments.

**#6117 also has no code.** Its diff against its base (#6225) is empty. It holds three
commits, and all three are chores:

```
170203e  chore: retrigger the QA review app build
071c74e  chore: retrigger the QA review app build
c4871af  chore: carry the combined branch for the QA review app
```

A PR with an empty diff cannot own a finding. There is no line in it to correct.

**"The only one anyone actually reviews" is the opposite of the truth here.** jmlacroix
reviewed four of the lower layers. He did not comment on #6117.

| PR | Human review comments |
|---|---|
| #6112 | 5 findings |
| #6113 | none |
| #6114 | 1 finding |
| #6115 | none |
| #6116 | none |
| #6266 | 2 findings |
| #6225 | 1 finding |
| **#6117** | **none** |

So I cannot do the task as you stated it. There is no work on #6117.

There is also a second reason not to put fixes there. #6117 is a carrier branch for the QA
review app. If you never merge it, then every fix that lands on it goes in the bin. The
lower PRs merge to staging without the fix.

## What is actually outstanding

There are 9 findings. jmlacroix wrote all of them. He marked all of them **advisory —
nothing blocks**. They all concern test reliability.

All 9 arrived as plain PR comments. GitHub cannot resolve these, so a reply is the only
possible acknowledgement. One reply per PR, not one reply per finding.

I confirmed each attribution with `git log -S` over the stack range. I did not trust the
file names alone.

### #6112 — 5 findings (bottom of the stack)

All five point at commit `40efb02a0c`. That commit is in #6112 only.

**1. `spec/factories/deployment.rb` — circular default. FIX.**
Real. The base factory sets `stopped_at { started_at + 10.minutes }`. The `:with_locations`
trait sets `started_at { stopped_at - 20.minutes }`. The two attributes derive from each
other, so the pair recurses.
The trap is latent today. All three current callers pass `stopped_at:`. The next caller
who forgets gets a stack overflow. The guard is one line, so I will add it.

**2. `spec/models/site_spec.rb:1732` — raw Timecop. FIX.**
Real. An `around { Timecop.freeze(...) }` sits inside `describe "#scan_summary_snapshot"`.
`TestSuiteTimeMachine` controls the suite clock (`spec/rails_helper.rb:19`), and the same
file already uses `time:` metadata at lines 780 and 797. I will move to the metadata and
delete the hook.

**3. `spec/queries/application_spec.rb` — hand-rolled SQL capture. FIX, with a correction.**
Real. `spec/support/sql_capture.rb` gives `queries_while`, and it already drops the SCHEMA
and TRANSACTION noise.
jmlacroix named one site. There are **two**: lines 207 and 221. I will replace both.

**4. `chatbot_scan_figure_parity_steps.rb:6` — `2.hours.ago` is not always today. FIX.**
Real. Cucumber runs on the real clock. For the first two hours after site-local midnight,
`2.hours.ago` falls on the previous day, and the step claims "today". I will clamp it as
he suggests.

**5. `features/chatbot/scan_figure_parity.feature` — double login. NEEDS YOUR DECISION.**
The Background does log in twice:
```
Given I am logged in as a warehouse operator
And I am a Dexory employee
```
`authentication_steps.rb:1` logs in. `chatbot_feature_flag_steps.rb:25` is a separate step.
jmlacroix offers two options that exclude each other, and the right one depends on intent
I do not hold:
- If the scenarios need staff access, use `I am logged in as a Dexory employee` alone.
- If they do not, drop the employee step and add `I have Adapt enabled`.

**Do these scenarios need staff access?** Tell me, and I will make the change.

### #6114 — 1 finding

Points at `5ece5d1064`, which is #6114's own commit.

**`tasks_dashboard_open_count` reads the badge too early. FIX.**
Real. The method visits a hand-built URL, then reads `find_testid("status-filter-open")`
the moment the node exists. The count is not in it yet.
Both replacements he names exist and do what he says:
`visit_tasks_list` (`system_navigation_helpers.rb:180`) waits for the React mount and then
the settle. Turning the Then step into a retrying `have_css` also removes the scrape.

### #6266 — 2 findings

Both point at `6366d53a12`, which is #6266's own commit.

**1. `chatbot_last_scan_scope_steps.rb:78` `run_finished_at` — inverted order. FIX, but not
his snippet as written.**
The bug is real and it is worse than a flake. At 00:00:30 site-local:
- "just now" = `now - 1.minute` = 23:59 **yesterday**
- "earlier today" = `max(now - 6.hours, beginning_of_day + 1.minute)` = 00:01 **today**

So "earlier today" is newer than "just now", and the wrong run becomes the newest.
His clamp does fix the order. It also puts both timestamps in the **future** for the first
two minutes after midnight, which contradicts the rule he applied in finding 4. I will fix
the order and keep both times in the past. I will show you the version I land.

**2. `spec/models/scan_snapshot_spec.rb:275` — two times must share a day. FIX, with two
corrections.**
The example uses `10.minutes.ago` and `20.minutes.ago` and needs them on one day.
- His cited precedent is wrong. `time:` metadata is at lines 401 and 423, not 339. The
  convention holds; only the line number is off.
- His window is wrong. The pair breaks between 00:10 and 00:20 site-local, not "right
  after midnight". At 00:05 both times still fall on yesterday.

The fix stands either way. I will pin the example, not the whole `describe`, because the
sibling examples do not need the pin.

### #6225 — 1 finding

Points at `6d0f22a31a`, which is #6225's own commit.

**`tasks_dashboard_row_count` — slow and fragile. FIX.**
Real. The method uses a hand-built URL, `wait: 20`, and `all("[role='row']").size`. With
no rows it waits the full 20 seconds for nothing.
`data_table_rows` (`system_test_helpers.rb:207`) waits the skeleton out first, and its own
comment explains the phantom-row bug that the current code can hit.
One caution: `visit_tasks_list` also calls `wait_for_data_table_settled`, so the swap does
not remove the `window.fetch` limit he mentions. It still adds the mount wait and the
skeleton wait, so it is a clear gain.

## One conflict to expect

Findings for **#6114** and **#6225** sit in the same file, in **adjacent methods**:
`chatbot_scan_figure_parity_steps.rb`, `tasks_dashboard_open_count` and
`tasks_dashboard_row_count`.

Two layers own two neighbouring methods. The cascade will conflict there. I will land
#6114 first, because it is lower, and then let #6225 rebase onto it. Keep the lower fix
when the conflict shows.

## The plan

1. One agent per owning PR, in its own worktree: **#6112**, **#6114**, **#6266**, **#6225**.
   No agent on #6117, because #6117 owns nothing.
2. Reply first, while the comments still sit against the diff. One comment per PR, and it
   follows jmlacroix's own numbering.
3. Cascade once, at the end: `gh stack rebase`, then `gh stack submit --auto`.
4. Resolve nothing. These are plain PR comments, so GitHub gives no resolve action.

## Before I start

Two things need you:

1. **Finding 5 (#6112): do the parity scenarios need staff access?** The two options
   exclude each other and I will not guess.
2. **Do you want this round at all?** jmlacroix marked every finding advisory and said
   nothing blocks. The changes are cheap and they remove real midnight flakes, so I think
   they are worth it. But they touch four branches and force a full cascade. If you want
   #6117 in front of QA now, then say so and I will hold.

Say go, and answer question 1, and I will run it.

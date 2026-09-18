# PR 6266 — jmlacroix test-reliability comment

That one comment holds **two separate findings**, and both are about code that PR 6266 itself adds. No other PR in the stack owns them, so no cascade is necessary. The comment is advisory. Nothing blocks the PR.

I did not change any file, post a reply or resolve the thread. This is the plan only.

## Finding 1 — cucumber step timestamps near site midnight

`features/step_definitions/chatbot_last_scan_scope_steps.rb:78-84`

**The problem is real.** If the suite runs in the first minute after midnight in the site timezone (Europe/London for the fixture site), then:

- `"just now"` = `fresh_site.now - 1.minute` = yesterday, 23:59.
- `"earlier today"` = `max(now - 6.hours, beginning_of_day + 1.minute)` = today, 00:01.

So "earlier today" is **later** than "just now". The run that must be the newest is then the oldest, and the two runs no longer share a scan day. Scenario 1 ("The last scan is the latest run, not every run from the same day") fails.

**But I do not recommend the fix as written.** The suggestion clamps `"just now"` to `beginning_of_day + 2.minutes`. Between 00:00 and 00:02 site time, that puts `stopped_at` in the **future**. `ScanSnapshot` caps its window at `site.now`:

```ruby
# app/models/scan_snapshot.rb:11
@up_to_datetime = [site.now, @up_to_datetime].min
```

A scan that stops after that cap drops out of the snapshot completely. The "just now" run then becomes invisible, and scenarios 1, 3, 4 and 5 fail — with a more confusing symptom than the one we started with (an empty last scan, not a wrongly ordered one). The clamp on `"earlier today"` has the same defect between 00:00 and 00:01. In total the change moves a 1-minute failure window to a ~2-minute one. It does not close it.

**Recommended fix — freeze the clock, as the repo already does elsewhere.** `features/step_definitions/task_manager_steps.rb:10-15` has a `@frozen_clock` tag with `Before`/`After` hooks that freeze at `Time.current.midday`, for exactly this reason (its comment names the site-timezone day boundary). Cucumber hooks are global, so:

1. Tag `features/chatbot/last_scan_scope.feature` with `@frozen_clock`.
2. Simplify the helper, because the clamps are then unnecessary:
   ```ruby
   when "just now" then fresh_site.now - 1.minute
   when "earlier today" then fresh_site.now - 6.hours
   ```
3. Replace the comment above `run_finished_at`, which currently promises the timestamps hold "whatever the clock says". With a frozen midday clock the day is no longer at risk, so the comment can go.
4. The midnight-crossing step (line 16) stays correct: midday minus one day, plus or minus an hour, is still in the past.

One caveat to weigh: the `@frozen_clock` hook lives in an unrelated step file. Tagging a chatbot feature with a hook defined in `task_manager_steps.rb` is obscure. My preference is to move those hooks to `features/support/frozen_clock.rb` in this PR, so the tag is discoverable. That touches a file this PR does not otherwise change, so tell me if you would rather keep the diff tight and accept the implicit dependency.

If you want to keep relative times and not freeze, the honest version of the suggestion is to clamp **away from midnight in the past direction** — for example, both runs derived from `min(now, beginning_of_day + 12.hours)`. I still prefer the freeze: it is one tag, and it matches existing practice.

## Finding 2 — `scan_snapshot_spec.rb` ad-hoc example

`spec/models/scan_snapshot_spec.rb:275-282` ("keeps the newest day's ad-hoc scans when the newest scan had no run")

**This one holds up in full, and the fix is correct.** The example needs `10.minutes.ago` and `20.minutes.ago` on the same site day, because `latest_run_keys` keys an ad-hoc newest scan by day alone (`app/models/scan_snapshot.rb:201-208`) and `ScheduleFiltering` matches the day in the site timezone. `spec/rails_helper.rb:19` pins the clock at boot with `TestSuiteTimeMachine.pretend_it_is("real_world")`, so a suite that boots between 00:00 and 00:20 London time straddles midnight, `adhoc_earlier` falls on the day before, and `contain_exactly` fails.

**Plan:** pin the clock with `time:` metadata, the same mechanism already used at lines 401 and 423 of that file. I would put it on the single example rather than on a wrapping context, so the pin covers only what needs it:

```ruby
it "keeps the newest day's ad-hoc scans when the newest scan had no run", time: "2026-08-20 09:00 UTC" do
```

`let!` and `before` blocks run inside that hook, so `newest` and `same_run` move with the pinned clock. 09:00 UTC gives clearance on both sides of the London day boundary.

## Verification

Both files are on `markahesketh/adapt-last-scan-query`, which is not the branch in the working tree now. After you approve I will check that branch out and:

- `bin/rspec spec/models/scan_snapshot_spec.rb` — normal run.
- Reproduce the flake first, then confirm the fix: `TEST_DATE_AND_TIME="2026-08-20 00:05 Europe/London" bin/rspec spec/models/scan_snapshot_spec.rb`. The example must fail before the change and pass after it.
- `bundle exec cucumber --profile compact features/chatbot/last_scan_scope.feature`. Cucumber has no `TEST_DATE_AND_TIME` hook, so to prove finding 1 I will freeze the clock near midnight for one throwaway run, watch scenario 1 fail, then apply the `@frozen_clock` tag and re-run.
- `bin/lint` on the touched files.

## What I need from you

1. Agreement on the freeze over the clamp for finding 1.
2. A decision on moving the `@frozen_clock` hooks to `features/support/`, or keeping the diff tight.
3. Whether you want me to reply to jmlacroix on the thread — in particular to record why the `"just now"` clamp is unsafe, since he may apply the same suggestion to other PRs.

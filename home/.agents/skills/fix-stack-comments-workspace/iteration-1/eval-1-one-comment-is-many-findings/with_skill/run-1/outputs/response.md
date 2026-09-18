# Plan: Jean-Michel's test-reliability comment on #6266

One comment, but two separate findings. I did not change any file. Here is the plan.

## What the comment is

[jmlacroix, 15 Sep](https://github.com/botsandus/DexoryView/pull/6266#issuecomment-5683905443) is a plain PR comment (not an inline thread), so GitHub cannot resolve it. He marks it advisory: "nothing blocks". It has two numbered items about different files. The unit of work is the finding, so I treat it as two.

He posted the same kind of comment on #6112 (5 items), #6114 (1 item) and #6225 (1 item). Those are not in this task. See "One thing to decide" at the end.

## Ownership

Both findings belong to #6266. I confirmed this, I did not trust the attribution:

- `features/step_definitions/chatbot_last_scan_scope_steps.rb` is a new file. Only `6366d53a12` and `30267054bd` touch it, and both commits are in the #6266 layer.
- `spec/models/scan_snapshot_spec.rb` is touched by three layers (#6116 and #6266). But `git log -S "keeps the newest day's ad-hoc scans"` gives only `6366d53a12`, which is #6266.

No fix must move down the stack.

## Finding 1: the `run_finished_at` helper

`features/step_definitions/chatbot_last_scan_scope_steps.rb:78-84`

**The diagnosis is correct.** In the first minute after midnight in the site timezone (Europe/London, from the site factory):

- `"just now"` is `fresh_site.now - 1.minute`, which is yesterday.
- `"earlier today"` is `[now - 6.hours, beginning_of_day + 1.minute].max`, which becomes today 00:01.

So `"earlier today"` is newer than `"just now"`. The scenario "The last scan is the latest run, not every run from the same day" then asserts the wrong run. Cucumber gets no help from the suite clock: `features/support/env.rb` does not load `spec/rails_helper.rb`, so `TestSuiteTimeMachine` and `TEST_DATE_AND_TIME` do not apply to cucumber. The comment on lines 76-77 claims a property that the code does not have.

**But his suggested fix does not work.** He asks for `"just now" → [fresh_site.now - 1.minute, fresh_site.now.beginning_of_day + 2.minutes].max`. That timestamp is in the future for the first two minutes of the day, and a future scan disappears from the snapshot:

- `ScanSnapshot#initialize` caps the window: `@up_to_datetime = [site.now, @up_to_datetime].min` (`app/models/scan_snapshot.rb:11`).
- `Deployment.most_recent_for_name` then filters `stopped_at: ...(up_to_datetime + 1.second)` (`app/models/deployment.rb:126`).

So the clamp trades a wrong-order flake for an empty-result failure. The `"earlier today"` branch has the same defect today. And there is no way out by clamping: the scenario needs two scans in the past, in the same site day, in a fixed order. Just after midnight the past part of that day is only a few seconds long.

**My fix: freeze the clock for the feature.** We already have this exact tool, with a comment that describes this exact problem:

```ruby
Before("@frozen_clock") do
  Timecop.freeze(Time.current.midday)
end
```
(`features/step_definitions/task_manager_steps.rb:9-15`)

I would:

1. Tag `features/chatbot/last_scan_scope.feature` with `@frozen_clock`.
2. Move that `Before`/`After` pair into `features/support/hooks.rb`, because a tag hook shared by two unrelated features must not live in one feature's step file.
3. Leave `run_finished_at` as relative offsets, and delete the `beginning_of_day` clamp on `"earlier today"`, because the clamp only exists to fight the real clock.
4. Correct the comment on lines 76-77.

The scenarios read code in-process through the sandbox (`the chatbot sandbox runs code in-process`), so `Timecop` reaches every clock the assertions use. There is no browser clock to disagree.

**Verification:** run `bundle exec cucumber --profile compact features/chatbot/last_scan_scope.feature`. To prove the flake before the fix, set the site timezone to a zone where local time is just past midnight now, or freeze at site-local midnight plus 30 seconds. Both make the failure repeatable instead of once a day.

## Finding 2: the ad-hoc scan example

`spec/models/scan_snapshot_spec.rb:275`

**Correct, and his fix is right.** `latest_scan` keys an ad-hoc newest scan by its day, so the example needs `10.minutes.ago` and `20.minutes.ago` in the same site day. The suite clock is `real_world` by default (`spec/rails_helper.rb:19`), so the example fails in the first 20 minutes after London midnight.

I would add `time: "2026-08-20 09:00 UTC"`. Two small corrections to his note:

- It is an `it`, not a `context`, so the metadata goes on the example.
- The pattern in this file is at lines 401 and 423, not 339.

I would pin the one example, not the whole `describe "#latest_scan"`. The neighbouring examples group by `schedule_run_id`, so the day boundary does not affect them, and a narrow pin says which example needs the clock.

**Verification:** `bin/rspec spec/models/scan_snapshot_spec.rb`, then the same file with `TEST_DATE_AND_TIME="2026-08-20 00:05 UTC"` to show the example survives the bad window.

## Reply and resolve

The findings arrived in an issue comment, so there is no thread and no resolve action. One comment on #6266 that answers both items in his numbering. Draft:

> Thanks, both of these hold up. Number 2 is in: the example now pins the clock with `time: "2026-08-20 09:00 UTC"`, same as the two contexts further down the file. (It's an `it` rather than a `context`, so the metadata went on the example.)
>
> Number 1 I've fixed a different way. The clamp puts `"just now"` at `beginning_of_day + 2.minutes`, which is in the future for the first two minutes of the day, and a future `stopped_at` drops out of the snapshot altogether: `ScanSnapshot` caps `up_to` at `site.now`, and `most_recent_for_name` filters on it. So we'd swap a wrong-order flake for an empty-result one. The current `"earlier today"` clamp has the same problem. There's also no arrangement that works, since the scenario needs two past scans in the same site day in a fixed order, and just after midnight that day has no past to speak of.
>
> Instead the feature now carries `@frozen_clock` (the `Timecop.freeze(Time.current.midday)` hook from `task_manager_steps.rb`, which I've moved into `features/support/hooks.rb` since two features share it now). The offsets go back to being plain relative times. The scenarios run the sandbox in-process, so Timecop covers everything they read.

## Cascade

#6225 and #6117 sit above #6266, so a fix here invalidates both. After the commit is pushed on `markahesketh/adapt-last-scan-query`:

```sh
gh stack rebase
gh stack submit --auto
```

Once only, by me, and after the reply goes up.

## One thing to decide

The #6112 comment has an item about the same bug class in the sibling helper: `stopped_at: 2.hours.ago` in `chatbot_scan_figure_parity_steps.rb`, which is yesterday for the first two hours after midnight. Jean-Michel proposes clamping there too, and that clamp has the same future-timestamp problem as this one.

Two questions:

1. Do you want the same `@frozen_clock` answer in both places? If so, the two fixes should land together, because both edit the same helper family and the #6112 fix must go in the lower layer.
2. If you fix #6266 alone now, the stack cascades twice, once now and once when #6112, #6114 and #6225 get their fixes. One round for all four is less work and fewer conflicts.

Tell me which, and I will start.

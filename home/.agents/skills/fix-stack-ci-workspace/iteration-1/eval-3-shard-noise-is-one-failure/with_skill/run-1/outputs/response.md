No. It is one failure, seen three times.

## The shard numbers tell you nothing

CI splits the cucumber suite dynamically with knapsack. The same scenario lands in a
different shard number on each run. "Test Cucumber (15, 26)", "(6, 26)" and "(25, 26)"
are three different buckets that each held the same scenario.

I read the three failed jobs. All three report the same thing:

```
cucumber -p knapsack features/chatbot/scan_figure_parity.feature:17
  # Scenario: Counts match the page when an older scan is still inside the freshness window
  uninitialized constant Query::ScanSummaryOccupancy (NameError)
```

One scenario. One error. Track the test identity, not the job name.

## The origin is 6112, and it is already fixed

The step definition that calls `Query::ScanSummaryOccupancy` came in with PR 6112, the
bottom of the stack. 6113 and 6114 inherited it. That is why all three went red.

Your commit `46c7aff` on 6112 ("fix: compare the latest-scan-day figure with the
warehouse view's day card") removed the bad constant. It replaced `occupancy_card_total`
with `day_card_total`, which calls `Query::ScanSummary`. The constant is gone from all
three branch heads, and 6113 and 6114 both contain that commit.

The runs you looked at are from 15 Sep 11:40. Newer runs exist:

| PR   | head      | latest "Run Tests" |
|------|-----------|--------------------|
| 6112 | `46c7aff` | pass               |
| 6113 | `b4c730d` | pass               |
| 6114 | `5ece5d1` | fail               |

So there is no cucumber work to split. You fixed it in the right place already.

## What is still red

**6114 — one rspec failure, probably a flake.**
`spec/system/virtual_environment/item_analytics_spec.rb:190`
"Item Analytics with multiple location types the CSV includes the location type column".
`Capybara::ElementNotFound: Unable to find link or button "Export"`.

Two reasons to doubt it is real:
- 6114 changes `ar_sandbox_client.rb`, the sandbox routes, an `open-tasks.md` metric doc
  and the scan-parity feature. It touches nothing in item analytics or CSV export.
- The previous 6114 commit (`37dd9ec`) passed the full suite.

This failed on one layer only, which cannot be told apart from a flake on one run. Re-run
that job first. If it fails again, read
`docs/guides/debugging-system-tests/` before you touch the spec — a missing button in a
download helper is usually a waiting problem, not a code problem.

"Check for build success" on 6114 is the aggregate gate. It goes green when the rspec job
does.

**6112 — "Code owner review" fails.** It needs a review from
`@botsandus/applications` for `app/queries/application.rb`. Not a test. Request the review.

**All three — "Workflow" is pending.** It wants one of the QA labels. It will sit pending
until you add one.

## How to split the work

There is nothing to parallelise. The order is:

1. Re-run the failed rspec job on 6114. Wait for it.
2. Ask for the code owner review on 6112.
3. Add the QA label to all three.
4. If the rspec failure returns, fix it in 6114 — it is the top layer, so nothing
   inherits it.

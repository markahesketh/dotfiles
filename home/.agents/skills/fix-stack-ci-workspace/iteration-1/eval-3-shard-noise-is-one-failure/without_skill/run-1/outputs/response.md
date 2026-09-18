No. It is one failure, not three. Do not split the work.

## The shard number tells you nothing

The number in `Test Cucumber (15, 26)` is the CI node index, not a fixed part
of the suite. CI runs `knapsack_pro:queue:cucumber`, which gives work to the
nodes dynamically. The same scenario can go to a different node in each run.
Three different numbers are normal noise.

## All three runs failed on the same scenario

- PR 6112, run 34964574998, node 15
- PR 6113, run 34964581752, node 6
- PR 6114, run 34964589601, node 25

Each one stopped here:

```
features/chatbot/scan_figure_parity.feature:17
  Scenario: Counts match the page when an older scan is still inside the freshness window
  uninitialized constant Query::ScanSummaryOccupancy (NameError)
  ./features/step_definitions/chatbot_scan_figure_parity_steps.rb, in `occupancy_card_total'
```

The feature file and the step file come from PR 6112, the bottom of the stack.
PRs 6113 and 6114 contain the same broken code, because they are stacked on
6112. The correct place for the fix is 6112 only.

## The fix is already in

Commit `46c7aff9` on 6112 ("fix: compare the latest-scan-day figure with the
warehouse view's day card") removes the `Query::ScanSummaryOccupancy` call. All
three branch heads (`46c7aff9`, `b4c730dd`, `5ece5d10`) no longer contain that
constant. The failures you quote are from 15 September, 11:40 UTC. They are
stale.

The most recent `Run Tests` results:

| PR | Run | Result |
|----|-----|--------|
| 6112 | 34983119060 | pass |
| 6113 | 34983125794 | pass |
| 6114 | 34983129939 | fail — `Test Ruby (32, 34)` |

## What is still red

PR 6114 has one failure, and it is not cucumber:

```
spec/system/virtual_environment/item_analytics_spec.rb:190
  Item Analytics with multiple location types the CSV includes the location type column
  Capybara::ElementNotFound
  ./spec/support/system_test_helpers.rb:155, in `download_and_parse_csv_report'
```

This looks like a flake, not a regression:

- The diff of 6114 touches only chatbot sandbox code, a metrics document, the
  routes for the sandbox, and the parity feature. It does not touch item
  analytics or CSV export.
- The same branch passed at commit `37dd9ec2` (run 34975840502).
- `download_and_parse_csv_report` clicks the "Export" menu open, clicks the
  trigger, then clicks "Export" again to close it. That third click fails if the
  menu is already closed. This is a known type of timing problem.

## What to do

1. Do nothing on 6113 and 6114 for the cucumber failure. It is fixed at its
   source in 6112.
2. Run `Test Ruby` again on 6114. If the item analytics spec fails a second
   time, then look at the menu wait in `download_and_parse_csv_report`. Do not
   add a `sleep`.
3. PR 6112 also needs a code owner review for `app/queries/application.rb`
   (@botsandus/applications, @alexspeller). All three PRs need one of the QA
   labels before they can merge.

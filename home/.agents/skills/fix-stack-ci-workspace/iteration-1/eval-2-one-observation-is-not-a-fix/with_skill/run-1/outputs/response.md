# There is no fix in 6115 to move down

I did not change anything. The premise does not hold: 6115 does not contain a fix. The
test is flaky, and 6115 only looks green because the retry gem hid the same failure.

## What the evidence shows

**The same example fails on 6115 too.**

- PR 6114, run 34983129939, job `Test Ruby (32, 34)`:
  `spec/system/virtual_environment/item_analytics_spec.rb:190` — "Item Analytics with
  multiple location types the CSV includes the location type column".
  Error: `Capybara::ElementNotFound: Unable to find link or button "Export"`.
  It failed on all 3 tries, so the job went red.
- PR 6115, run 34983133802, job `Test Ruby (9, 34)`: the **same example**, the **same
  error**. It failed on try 1 and passed on try 2. The log says:
  `./spec/system/virtual_environment/item_analytics_spec.rb:190 — passed on attempt 2`.
  RSpec::Rebound made the job green.
- In that same 6115 job, `item_analytics_spec.rb:62` also failed on try 1
  (`expected not to find visible css "[data-testid='item_analytics_data_table_skeleton']"`)
  and passed on try 2. This is the same fault, seen a second way.

**The 6115 diff cannot fix this test.** `git diff 6114..6115` touches only the
consolidation planner and chatbot files:
`app/queries/inventory_consolidation.rb`, `app/services/chat_bot/...`,
`app/data_tables/consolidation_planner_data_table.rb` and their specs. No layer in the
stack changes `item_analytics_spec.rb`, the item analytics page, or the data table.

**CI allocation differs between the two runs, so the grid is not comparable.** Knapsack
gave 6114 seed 1016 and 6115 seed 15138, with different file groups per shard. The green
above is a different shard and a different order, not a different code state.

The collector classified this as `unconfirmed`, not `fixed-higher`. That was correct.

## The actual root cause

`app/javascript/components/DataTable/DataTable.tsx:51` states the toolbar is "Not rendered
while the skeleton is showing". `ExportPopover` lives in that toolbar.

The spec asserts the heading text, then clicks "Export" immediately
(`spec/support/system_test_helpers.rb:155`). The heading renders before the deferred data
table resolves. So the click races the table load. When the table is slow, the button does
not exist yet.

## What I recommend instead

1. Make the export helper wait for the table before it clicks. Add an assertion that the
   skeleton has gone (`item_analytics_data_table_skeleton`, or the generic data-table
   equivalent) before the first `click_link_or_button` in
   `/Users/markhesketh/Code/DexoryView/spec/support/system_test_helpers.rb:153`.
   Read `/Users/markhesketh/Code/DexoryView/docs/guides/debugging-system-tests/01-the-waiting-model.md`
   first. Do not add a `sleep` or a retry.
2. Put the fix in a new PR on `staging`, not in 6114. The flake is older than the stack
   and belongs to no layer in it.
3. Re-run 6114 to clear the red tick once the flake fix has landed and the stack is
   rebased.

## Other stack notes (not part of this task)

- PR 6116 has no completed run. It cannot witness anything. It needs a re-run.
- PR 6112's red check is the "Code owner review" commit status, not a test.
- PR 6117 skipped Lint, Test JavaScript, Test Python and Test RLS provisioning. Those
  render green but ran nothing.

Tell me if you want the helper fix prepared as its own PR.

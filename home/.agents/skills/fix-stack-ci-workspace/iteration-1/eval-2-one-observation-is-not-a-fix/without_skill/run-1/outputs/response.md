# There is no fix in 6115 to move down

I did not make changes. The premise is wrong, so a move would move nothing.

## What the logs show

The test failed on both PRs. On 6115 a retry hid it.

PR 6114, job `Test Ruby (32, 34)`:

```
1st Try error in ./spec/system/virtual_environment/item_analytics_spec.rb:190:
RSpec::Rebound: 2nd try ...
2nd Try error in ...:190:
RSpec::Rebound: 3rd try ...
483 examples, 1 failure
```

PR 6115, job `Test Ruby (9, 34)`:

```
1st Try error in ./spec/system/virtual_environment/item_analytics_spec.rb:190:
Unable to find link or button "Export"
RSpec::Rebound: 2nd try ./spec/system/virtual_environment/item_analytics_spec.rb:190
```

The second try passed, so the job was green. The same scenario, the same line
and the same error occurred on both PRs. 6115 is green by luck, not by a fix.
The same node on 6115 also retried line 62 of the same file.

## The commits agree

Neither commit can touch this page:

- 6114 `5ece5d1064` changes the chatbot AR sandbox, the sandbox route, an
  open-tasks metric and a cucumber feature.
- 6115 `518f4992cc` changes `Query::InventoryConsolidation`, the consolidation
  data table, a chatbot scene and a metric definition.

No commit touches the Item Analytics page, the Export control, or
`spec/support/system_test_helpers.rb`. There is no path from the consolidation
query to a missing Export button.

## The true cause

The failure is a wait problem in the test, not a defect in the stack.

- Line 190, `"the CSV includes the location type column"`, waits only for the
  heading text `"Item Analytics as of 10th Nov 2023"`. Then it calls
  `download_and_parse_csv_report`, which immediately clicks `"Export"`.
- The heading comes from the page. The Export control comes from the data
  table toolbar. PR #6185 made the item analytics table load only when its
  panel opens, so the table arrives later than the heading.
- The other scenarios in the file call `expect_data_table_rows`, which waits
  for the table. This scenario does not. Thus only this scenario is unstable.
- The example took 58 seconds on the slow node of 6114. A slow node makes the
  gap larger, so the flake occurs more frequently there.

## What I recommend instead

Do the fix on 6114 as you asked, but write it new. Do not copy from 6115.

1. In `spec/system/virtual_environment/item_analytics_spec.rb`, before the
   download at line 192, wait for the table. Use the existing helper
   `wait_for_data_table_settled` from `spec/support/reliable_click.rb`. It
   waits for the absence of `[data-testid$='_data_table_skeleton']`, which is
   the signal that the deferred Inertia data prop landed.
2. Alternatively, put the wait in `download_and_parse_csv_report` in
   `spec/support/system_test_helpers.rb`. This makes all CSV downloads safe,
   but it changes many specs at the same time. The single-scenario fix is
   smaller and safer.
3. Do not add `sleep` and do not add a retry. See
   `docs/guides/debugging-system-tests/06-anti-patterns.md`.

One more point about the stack: 6114 is also the wrong owner. The flake exists
below 6114 too, because no commit in 6113, 6114 or 6115 touches this code. If
you want the fix in the merge path at the correct place, put it at the base of
the stack, or in a separate PR against staging. I stopped here as instructed,
so nothing is changed.

## Also seen

PR 6116 shows a red `Test Ruby (17, 34)`. That job has the status `cancelled`,
not a test failure. Examine it separately.

Relevant files:

- `/Users/markhesketh/Code/DexoryView/spec/system/virtual_environment/item_analytics_spec.rb`
- `/Users/markhesketh/Code/DexoryView/spec/support/system_test_helpers.rb`
- `/Users/markhesketh/Code/DexoryView/spec/support/reliable_click.rb`

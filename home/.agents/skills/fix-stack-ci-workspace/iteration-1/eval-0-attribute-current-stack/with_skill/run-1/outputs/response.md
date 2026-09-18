# Stack #6267 — what is broken, and where

I changed nothing. This is the plan only.

## Short answer

The stack has **no real code bug**. One test failed one time, and that test is a
known-bad system test that also fails on `staging`. The other red and yellow marks
are gates and run problems, not test problems.

## The stack, bottom to top

| Layer | PR | Branch | Test result |
|---|---|---|---|
| 1 (bottom) | 6112 | adapt-metrics-definitions | Tests pass. Gate is red. |
| 2 | 6113 | adapt-slotting-access | Tests pass. |
| 3 | 6114 | adapt-task-parity | 1 test failed. |
| 4 | 6115 | adapt-consolidation-planner | Tests pass. |
| 5 | 6116 | adapt-obstruction-denominator | Run cancelled. No result. |
| 6 | 6266 | adapt-last-scan-query | Tests pass. |
| 7 | 6225 | adapt-correctness-tasks-filter | Tests pass. |
| 8 (top) | 6117 | adapt-data-correctness-qa | Empty branch. Checks skipped. |

## Finding 1 — the only failed test is a flake, not a stack bug

`rspec spec/system/virtual_environment/item_analytics_spec.rb:190`
("Item Analytics with multiple location types the CSV includes the location type column")
failed in run 34983129939, shard `Test Ruby (32, 34)`, on PR 6114.

The error is:

```
Failure/Error: click_link_or_button group_name if group_name.present?
Capybara::ElementNotFound:
  Unable to find link or button "Export"
```

Four facts show that PR 6114 did not cause this:

1. **The same test failed on `staging`** in run 35036473023, shard `Test Ruby (7, 29)`,
   at 23:37 on 15 Sep. No stack code is in `staging`. This is the strongest proof.
2. **The test file is identical everywhere.** The blob hash of
   `/Users/markhesketh/Code/DexoryView/spec/system/virtual_environment/item_analytics_spec.rb`
   is `16454d3b` on all eight branches and on `staging`. The helper
   `/Users/markhesketh/Code/DexoryView/spec/support/system_test_helpers.rb` is `dd8666de`
   everywhere.
3. **PR 6114 touches nothing near this page.** Its files are the chatbot AR sandbox,
   `app/services/chat_bot/metrics/open-tasks.md`, `config/routes/sandbox.rb` and two
   cucumber files. The Export control comes from the DataTable toolbar
   (`/Users/markhesketh/Code/DexoryView/app/javascript/components/DataTable/toolbar/ExportPopover.stories.tsx`).
4. **The layers above pass.** 6115, 6266 and 6225 all ran this shard green.

The collector labelled this "unconfirmed" and pointed at 6115 as a possible fix. There is
no fix in 6115. Nothing moves down.

**Probable root cause.** The test took 58 seconds, which is the slowest example in the
shard. The step `expect(page).to have_text("Item Analytics as of 10th Nov 2023")` passed
first, so the page header was there. The Export control was not. The Export control is
part of the data table toolbar, so it mounts only after the table loads. On a loaded CI
runner the toolbar was still not present when Capybara gave up. The helper at
`/Users/markhesketh/Code/DexoryView/spec/support/system_test_helpers.rb:153-158` clicks
"Export" with no wait on the table being ready.

## Finding 2 — PR 6112 is blocked by a review gate, not by code

The red check on 6112 is the commit status **"Code owner review"**:

```
Owner review needed: app/queries/application.rb (@botsandus/applications @alexspeller) +1 more
```

All 77 of its workflow checks ran green, including all 34 Ruby shards and all 26 Cucumber
shards. No code change can clear this. It needs the named code owners to review.

## Finding 3 — PR 6116 has no verdict

Run 34983144693 ended `cancelled`. Shard `Test Ruby (17, 34)` shows
`##[error]The operation was canceled.` with no rspec failure before it. `gh pr checks`
prints this as `fail`, which is wrong. A cancelled run is not a pass and not a failure.

There is good indirect evidence that 6116 is fine: PR 6266 contains every commit of 6116
and passed Run Tests at its current head `7f4dd59d`. But 6116's own status stays red until
somebody re-runs it.

## Finding 4 — PR 6117 proves nothing

6117 is a carrier branch for the QA review app. Its diff against 6225 is empty. Its three
commits are all `chore:` no-op commits. Path filters therefore skipped Lint, Test
JavaScript, Test Python, Test RLS provisioning and the code-owner gate. It ran only 8
checks. Its green colour is not evidence that anything works.

## Finding 5 — two stack hygiene items

- **Every PR shows "Workflow" as pending**, with the text "One of QA Pass, No QA, Staging
  QA, Production QA, or Staging Product QA labels required". This gate never ends by
  itself. Do not wait on it. Watch the run IDs instead.
- **The bottom of the stack is 24 commits behind `staging`.** The stack itself is clean
  and linear: each layer fully contains its parent, and no layer is behind its parent.
- GitHub reports PR 6115 as `CONFLICTING`. A local `git merge-tree` of 6114 and 6115 gives
  a clean tree with no conflict. GitHub's data is stale. It will clear on the next push.

## The plan

Nothing here needs an agent, and nothing here needs a fix at a lower layer. I would do
this, in this order:

1. **Re-run Run Tests on PR 6116** (run 34983144693). This is a re-run, not a fix. It
   turns the only unknown layer into a real result.
2. **Chase the code owners on PR 6112** — `@botsandus/applications` and `@alexspeller`,
   for `app/queries/application.rb` and one more file. This is the only thing that holds
   the bottom of the stack.
3. **Decide about `item_analytics_spec.rb:190`.** It is a pre-existing `staging` flake, so
   it is not stack work and it must not be "fixed" inside PR 6114. I see two honest
   choices:
   - **Preferred:** fix the flake in its own PR off `staging`. Follow
     `/Users/markhesketh/Code/DexoryView/docs/guides/debugging-system-tests/README.md`,
     chapter 01 on the waiting model and chapter 02 on the diagnosis workflow. The likely
     correct change is to wait for the data table to be ready before the helper clicks
     "Export" — not a `sleep`, and not a wider matcher.
   - **Or:** accept it for now and re-run the shard on 6114 to clear the colour. This
     leaves the flake in place, and it will hit somebody else.
4. **After 1 and 2, rebase the stack once** with `gh stack rebase`, then
   `gh stack submit --auto`. This also refreshes the stale conflict flag on 6115 and puts
   the stack on current `staging`. Then verify once across all layers.
5. **Add a QA label** to each PR when you are ready, or the "Workflow" gate stays pending
   forever.

## What I want from you before I touch anything

- Do you agree that the item analytics flake is out of scope for this stack, and that it
  should get its own PR off `staging`?
- May I re-run CI on 6116, and on the failed shard of 6114?
- Do you want me to ask the code owners on 6112, or will you?

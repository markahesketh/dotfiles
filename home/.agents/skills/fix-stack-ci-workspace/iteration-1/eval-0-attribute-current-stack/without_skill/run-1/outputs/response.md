# Stack #6267 — CI status and plan

## The stack

Eight PRs. The base is `staging`.

| # | PR | Branch | Test workflow at current head |
|---|----|--------|-------------------------------|
| 1 | 6112 | adapt-metrics-definitions | success |
| 2 | 6113 | adapt-slotting-access | success |
| 3 | 6114 | adapt-task-parity | **failure** |
| 4 | 6115 | adapt-consolidation-planner | success |
| 5 | 6116 | adapt-obstruction-denominator | **cancelled** |
| 6 | 6266 | adapt-last-scan-query | success |
| 7 | 6225 | adapt-correctness-tasks-filter | success |
| 8 | 6117 | adapt-data-correctness-qa | success |

The chain is correctly cascaded. Each branch contains the branch below it. I checked
this with `git merge-base --is-ancestor`. No layer is out of order.

The base of the stack is **24 commits behind `staging`**.

## What is actually broken

### 1. PR 6114 — one system spec failed. Not caused by 6114.

`spec/system/virtual_environment/item_analytics_spec.rb:190`
"Item Analytics with multiple location types the CSV includes the location type column"

```
Capybara::ElementNotFound: Unable to find link or button "Export"
# ./spec/support/system_test_helpers.rb:155 in download_and_parse_csv_report
```

The example ran for 58 seconds and then did not find the Export menu button.

Attribution: 6114 does not change Item Analytics. The first layer that touches
`app/controllers/analytics_controller.rb`, `app/services/analytics/scan_overview.rb`
and `app/queries/trend_analytics.rb` is **6116**, which is two layers above 6114.
PR 6115 sits directly on 6114, contains everything 6114 contains, and passed in the
same CI wave (14:39). A strict superset passed. The content of 6114 therefore cannot
explain the failure.

My reading: this is a wait/timing failure in a system spec, not a code defect.

One gap you should know about: shard 32 failed on attempt 1 of that run as well. The
attempt-1 log has expired, so I cannot prove attempt 1 failed on the *same* example.
That is the only unverified point in this report.

### 2. PR 6116 — no test failed. The runner ran out of time.

Job `Test Ruby (17, 34)` was cancelled at exactly 20 minutes. `.github/workflows/test.yml`
sets `timeout-minutes: 20`. The log shows passing examples right up to the cut. There
are zero failures.

The cause is the re-run, not the code. Both the 6114 run and the 6116 run are
`run_attempt: 2` — someone used "re-run failed jobs". On attempt 1 all 34 Ruby shards
ran 14:41–14:50. On the re-run, the one surviving shard started alone at 15:28 and had
to drain the Knapsack queue by itself. One shard cannot do the work of 34 in 20 minutes.

This is an artefact of re-running a single shard in Knapsack Queue mode. It tells you
nothing about 6116.

### 3. PR 6112 — code owner review gate is red. Not a test.

```
Owner review needed:
  app/queries/application.rb            → @botsandus/applications or @alexspeller
  app/services/chat_bot/codebase_knowledge.md → @botsandus/applications or @alexspeller
```

This is the correct layer. 6112 is the PR that changes
`Query::Application.with_session_settings`. The gate needs a human review.

### 4. All eight PRs — "Workflow" status is pending.

"One of QA Pass, No QA, Staging QA, Production QA, or Staging Product QA labels required."

This is a process gate. It needs a label from you, not a code change.

## Staleness risks that only appear after a rebase

`staging` has moved 24 commits. Three of them change how CI runs:

- `0656aa1033` re-split the runners. `staging` now uses 29 Ruby / 31 Cucumber shards.
  The stack still uses 34 / 26. Fewer Ruby shards means more work per shard, against
  the same 20-minute limit.
- `332520738e` bumped `knapsack_pro` to 8.4 and added a gate that fails CI when a test
  file never ran. This is a new way to go red.
- `603dddc01b` added a review-app opt-out label.

Six files are changed by both `staging` and the stack. Expect conflicts in:

- `db/structure.sql` — certain conflict. `staging` adds 8 migrations; the stack adds
  the chatbot GRANT migration.
- `app/models/site.rb`, `spec/models/site_spec.rb`
- `app/services/chat_bot/skills/space-utilisation.md`
- `evals/promptfoo/seed.rb`, `config/brakeman.ignore`

Two more overlaps to watch:

- `staging` commit `e585944bbd` already removed the `:basic` site factory trait from the
  eval and transfer harnesses. The tip commit of 6225 does the same thing for the sandbox
  spec. Check for a duplicate or an empty commit.
- `staging` commit `ac7cc9c008` changes Adapt consolidation reporting. That is the subject
  of 6115.

## My recommendation: change no code yet

Neither red is a proven defect. One is a timing flake in a spec no layer of this stack
touches. The other is a re-run artefact. If I "fix" either one now, I most probably fix
nothing and add noise to the diff.

## Plan

1. **Rebase the whole stack onto `staging`.** Do this first. You need it anyway — the
   base is 24 commits behind — and it gives every PR the current CI configuration.

2. **Regenerate `db/structure.sql`.** Do not merge the conflict by hand. Let the
   migrations produce the file.

3. **Check the two overlaps.** Confirm the 6225 `:basic` trait commit is still needed
   after `e585944bbd`. Confirm 6115 still agrees with `ac7cc9c008`.

4. **Let CI run in full on every PR.** Do not use "re-run failed jobs" on a single
   shard. That is what produced the 6116 timeout. If you must retry, re-run the whole
   workflow.

5. **Then judge the Item Analytics spec.** If it goes green, it was a flake and it
   needed nothing. If it stays red, I will run it locally, find the root cause, and fix
   it at the correct layer — which will be 6116 if the analytics change is to blame, and
   `staging` if it is not. I will follow
   `docs/guides/debugging-system-tests/02-diagnosis-workflow.md`. I will not add a
   `sleep` or a retry.

6. **Watch for the new "test file never ran" gate** after the rebase. It is new to the
   stack and can fail on its own.

7. **Ask for the code owner review on 6112.** `@alexspeller` or `@botsandus/applications`.
   Nothing in the code can clear it.

8. **Add the QA label to each PR.** Your decision, not mine.

Tell me to go, and I will start at step 1.

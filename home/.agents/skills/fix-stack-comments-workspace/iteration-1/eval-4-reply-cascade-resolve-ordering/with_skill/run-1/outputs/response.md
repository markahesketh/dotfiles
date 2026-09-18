# Stack #6267 — review feedback, 6112 up

I collected the feedback and checked every item against the source. I have made no
change. Here is the plan. Tell me to go and I will run it.

## What is outstanding

There are **9 findings** in total. All 9 come from one reviewer (jmlacroix), in **4 plain
PR comments** — one each on #6112, #6114, #6266 and #6225. There are **no inline review
threads** on any PR in the stack, and no CodeRabbit review: CodeRabbit skipped all 8 PRs
because they are drafts.

This matters for the process. A plain PR comment has no thread and no resolve button, so a
reply is the whole acknowledgement. There is nothing to resolve at the end.

The reviewer marked all four comments the same way: *"advisory, nothing blocks. Only the
findings that hold up against source."* I agree with that assessment. Every one of the 9
is a real test-reliability defect. I accept all 9.

#6113, #6115, #6116 and #6117 have no feedback at all.

## Findings, owners and decisions

| # | Raised on | Owns | Finding | Decision |
|---|---|---|---|---|
| 1 | #6112 | **#6112** | `spec/factories/deployment.rb` `:with_locations` — circular `started_at`/`stopped_at` | Fix |
| 2 | #6112 | **#6112** | `spec/models/site_spec.rb` — `around { Timecop.freeze }` instead of `time:` metadata | Fix |
| 3 | #6112 | **#6112** | `spec/queries/application_spec.rb` — hand-rolled SQL subscription | Fix, plus one extra example |
| 4 | #6112 | **#6112** | parity steps "scanned today" — `2.hours.ago` crosses midnight | Fix |
| 5 | #6112 | **#6112** | `scan_figure_parity.feature` Background logs in twice | Fix (option B) |
| 6 | #6114 | **#6114** | `tasks_dashboard_open_count` — reads the badge before the count lands | Fix |
| 7 | #6266 | **#6266** | `run_finished_at` — "just now" and "earlier today" invert after midnight | Fix |
| 8 | #6266 | **#6266** | `scan_snapshot_spec.rb` — two times must share a day | Fix, wider scope |
| 9 | #6225 | **#6225** | `tasks_dashboard_row_count` — hand-built URL, `wait: 20`, row scrape | Fix, reviewer's reason is wrong |

Every finding is owned by the PR it was raised on. Nothing has to move down a layer. I
checked this rather than trusting it, because the same file carries findings at three
different layers:

- `features/step_definitions/chatbot_scan_figure_parity_steps.rb` gets a finding from
  #6112 (finding 4), #6114 (finding 6) and #6225 (finding 9). Six layers touch this file.
- The `stopped_at: 2.hours.ago` line is ambiguous by the pickaxe: both `40efb02a0c`
  (#6112) and `6366d53a12` (#6266) changed a line with that text. I read the #6266 commit.
  It only adds `schedule_run_id:` to `scan_aisle`. Line 6, the one the reviewer means,
  comes from #6112. Owner: #6112.
- `tasks_dashboard_open_count` appears only in `5ece5d1064` (#6114).
  `tasks_dashboard_row_count` and `wait_for_data_table_settled` appear only in `6d0f22a31a`
  (#6225). Both are clean.

## Notes on the individual decisions

**Finding 1 is latent, not live.** The trait overrides `started_at { stopped_at - 20.minutes }`
while the base factory derives `stopped_at` from `started_at`. All 8 current callers pass
`stopped_at`, so nothing recurses today. The next caller who omits it gets a stack
overflow. The fix is one line. I will make it.

**Finding 3 goes one step past the ask.** The reviewer names the "sends one statement per
setting" example. The example directly above it, "applies the settings before the wrapped
statement", hand-rolls the same subscription. I will convert both to `queries_while`. Say
so if you want only the one the reviewer named.

**Finding 5 changes who the user is.** "I am logged in as a warehouse operator" creates a
customer, a site and a member user, then logs in. "I am a Dexory employee" then logs out,
creates a *different* admin user and logs in again. So `@user` is replaced by a Dexory
admin who is not a member of `@site`. I will take the reviewer's second option — drop the
employee step and add "I have Adapt enabled" — because the operator then holds both halves
of the Adapt gate, and `authentication_steps.rb` says in its own comment that this is the
pattern Adapt scenarios use.

This is the one finding with cross-layer risk. `@user` becomes the operator, and the
scenarios that #6114 and #6225 added to that feature use `@user` for task assignment. The
fix lands in #6112 but can break scenarios two and four layers up. I will run the whole
feature file after the cascade, not before.

**Finding 8 gets a wider scope.** The reviewer asks me to pin one example. The three
sibling examples in the same `describe "#latest_scan"` block carry the same day-boundary
assumption. I will pin the `describe`, which removes the hazard from all four. Say so if
you want only the one example.

**Finding 9 is right for the wrong reason.** The reviewer says
`wait_for_data_table_settled` "sees `window.fetch` only, not Inertia's XHR". That is not
what it does: it waits for the skeleton testid to disappear, which is the correct Inertia
signal, and it waits out Turbo requests first. The real defects are the two the reviewer's
own suggested replacement fixes: the settle can pass before React mounts the lazily
imported page (`visit_tasks_list` carries a comment about exactly this trap), and
`all("[role='row']")` waits the full timeout when the table is empty. So I will make the
change the reviewer asks for, and I will give the correct reason in the reply rather than
repeat the wrong one.

## Not per-PR work

- **No finding belongs to a different layer.** No stack restructure is needed, so no
  `gh stack modify` and no interactive session from you.
- **No finding is duplicated across layers.** Three findings share one file, but they are
  three separate defects with three separate owners.
- **No finding belongs to the trunk.** Everything points at code this stack introduced.

## What blocks "merge the lot", beyond the comments

Addressing the reviews does not make this stack mergeable. Four things are in the way, and
one of them needs you.

1. **All 8 PRs are drafts.** They need marking ready. I can do that on your word.
2. **Every PR shows `REVIEW_REQUIRED`, and #6112's "Code owner review" check is failing.**
   A code owner has to approve. I cannot approve your PRs for you, and jmlacroix's four
   comments are comments, not approvals. This is the real gate. Clearing all 9 findings
   gets you to "ready for review", not to "mergeable".
3. **The bottom of the stack is behind staging.** #6112 carries the ⚠ in `gh stack view`,
   and GitHub reports #6115 as `CONFLICTING`. The local chain itself is consistent — every
   layer sits on the one below. One cascade should clear both.
4. **Two PRs are not green.** #6116's failure is one cancelled RSpec shard, not a code
   failure; it needs a rerun. #6114 has one real failure,
   `spec/system/virtual_environment/item_analytics_spec.rb:190`, in a file the stack does
   not touch. It is a flake or an effect of the stale base. I will recheck it after the
   cascade rather than guess now.

## Order of work

**Step 1 — fix, one agent per owning PR: #6112, #6114, #6266, #6225.**
Four agents, in parallel, each in its own worktree (`/tmp/stack-comments-<pr>`), because a
branch can only be checked out once. Each agent owns every finding for its PR, is told that
the findings it can see on other layers belong elsewhere, and pushes only its own branch.
None of them runs `gh stack rebase`, `sync`, `push` or `submit`. The cascade is mine alone.
Never two agents on one branch.

**Step 2 — reply, one comment per PR, four comments.**
I depart from the skill's default order here, and it is worth saying why. The skill puts
replies before the cascade so a reply lands while its thread is still anchored to the diff.
There are no threads in this stack — all 9 findings are plain PR comments, which have no
anchor to strand. So nothing is lost by replying second, and replying after the fixes means
each reply can carry evidence of what actually changed. I will quote the reviewer's own
numbering, and I will name files and behaviour rather than commit SHAs, because Step 3
rewrites every SHA in the stack.

**Step 3 — cascade once.**
`gh stack rebase`, then `gh stack submit --auto`. Expect conflicts in
`chatbot_scan_figure_parity_steps.rb`: findings 4, 6 and 9 all edit that file at three
different layers. Resolving in favour of the lower layer is normally right.

**Step 4 — verify.**
Run `features/chatbot/scan_figure_parity.feature` in full (finding 5 changes the user for
scenarios owned by #6114 and #6225), plus `features/chatbot/last_scan_scope.feature`,
`spec/models/site_spec.rb`, `spec/models/scan_snapshot_spec.rb` and
`spec/queries/application_spec.rb`. Then rerun #6116's cancelled shard and recheck #6114's
`item_analytics_spec` failure on the rebased branch.

**Step 5 — nothing to resolve.**
There are no resolvable threads in this stack, so there is no resolve step. The four replies
are the complete acknowledgement.

**Step 6 — hand back to you.**
Mark the 8 PRs ready if you want that, and ask jmlacroix for the code-owner approval. Then
the stack can merge.

## Before I start

Three decisions are yours:

1. Findings 3 and 8 — do you want my wider scope, or only what the reviewer named?
2. Finding 5 — I chose "operator plus Adapt enabled" over "Dexory employee alone". Both
   satisfy the reviewer. Mine matches the documented pattern for Adapt scenarios and
   changes `@user` in scenarios two layers up. Tell me if you would rather keep staff access.
3. Shall I mark the 8 PRs ready to review as part of this, or leave them as drafts?

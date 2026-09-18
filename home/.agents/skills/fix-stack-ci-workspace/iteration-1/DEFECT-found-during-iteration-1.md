# Defect in collect_stack_failures.py, found by the eval-1 baseline run

NOT FIXED during iteration 1, deliberately: eight eval agents were already running against
this code, and changing it mid-run would mean different runs graded different software.
Fix after the iteration completes, then re-run.

## What is wrong

The skipped-check rule matches check names exactly. Sharded checks never match, because a
skipped matrix job keeps its unexpanded workflow template as its name:

    #6117  SKIPPED  Test Ruby
    #6117  SKIPPED  ${{ (((needs.changes.outputs.replay == 'true') && 'Test Cucumber
                    (replay)') || 'Test Cucumber') }} (${{ matrix.ci_node_index }},
                    ${{ matrix.ci_node_total }})
    #6225  SUCCESS  Test Cucumber (0, 26)   ... (1, 26) ... (25, 26)

So `Test Ruby` and `Test Cucumber` — the checks that actually carry the test evidence —
are invisible to the rule, while four unsharded ones (Lint, Test JavaScript, Test Python,
Test RLS provisioning) are caught. The rule works on exactly the checks that matter least.

This is the failure mode the skill itself warns about in Phase 2: CI shards tests
dynamically, so job names are not stable identities. The collector's own blindness rule
was written as though they were.

## The fix

Stop comparing names. Compare how many checks each layer executed against the stack median:

    #6117 ran 19 checks; every other layer ran 79-88.

A layer that ran a small fraction of its peers tested almost nothing, whichever names its
checks happened to carry. Immune to sharding, to template expansion, and to checks being
renamed between runs.

Credit: the eval-1 baseline run found this by counting checks per PR, which is what
prompted the comparison above.

---

# Second defect: a retry-rescued job is recorded as a clean pass

Found by the eval-2 baseline run. Also NOT fixed during iteration 1, same reason.

## What is wrong

This repo runs `RSpec::Rebound`, which re-runs a failed example in the same job. If a
later try passes, the job concludes SUCCESS and `statusCheckRollup` shows nothing unusual.
The collector reads that as a layer where the test passed.

On the live stack, item_analytics_spec.rb:190 failed on BOTH #6114 and #6115:

    #6114 Test Ruby (32, 34)   1st try fail, 2nd try fail, 3rd try fail  -> job FAILED
    #6115 Test Ruby  (9, 34)   1st try fail, 2nd try pass               -> job SUCCESS

So "fails at 6114, clears at 6115" is not two different outcomes. It is the same
instability, resolved differently by chance. The collector cannot see this, because the
distinction lives in the job log rather than in the check conclusion.

## Why it matters

It is the same class of error as counting a skipped check as a pass: something that is not
evidence of health is recorded as evidence of health. Here it is worse, because it
manufactures the boundary that `fixed-higher` and `unconfirmed` are both derived from. A
retry-rescued pass at layer N+1 invents a clearing layer that does not exist.

## The fix

When a failure clears at the next layer, grep that layer's job log for the retry marker
(`RSpec::Rebound`, `1st Try error`, or the equivalent for other frameworks) against the
same test identity. A rescued example means the layer did not clear it, and the pattern is
propagating rather than unconfirmed or fixed-higher.

The collector already downloads these logs to extract test identities, so the evidence is
in hand. It currently only parses them for failures.

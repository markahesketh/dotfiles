#!/usr/bin/env python3
"""Pin the attribution rules. Run: python3 test_collect_stack_failures.py

The cases named "regression" below are ones this classifier actually got wrong on a real
eight-PR stack: it twice reported "fixed-higher" from a single red run, which says a fix
already exists above and must be moved down rather than written. It also treated a PR
whose test jobs were skipped as the layer where a fix landed.
"""
import sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).parent))
from collect_stack_failures import classify

S = [1, 2, 3, 4, 5]
fails = []


def check(name, got, want):
    ok = got == want
    print(f"{'ok  ' if ok else 'FAIL'} {name}\n       got {got}, want {want}" if not ok
          else f"ok   {name}")
    if not ok:
        fails.append(name)


# Fails at its origin and never clears: a real regression, fix at the origin.
check("fails everywhere from origin up is propagating",
      classify(S, [2, 3, 4, 5]), ("propagating", None))
check("fails only at the top is propagating",
      classify(S, [5]), ("propagating", None))

# Two failures then clean: the clearing layer is meaningful.
check("two failures then green is fixed-higher",
      classify(S, [1, 2]), ("fixed-higher", 3))

# REGRESSION: one red run cannot distinguish a real fix above from a flake below.
check("regression: one failure then green is unconfirmed, not fixed-higher",
      classify(S, [2]), ("unconfirmed", 3))

# A hole inside the failing range means the result is not reproducible.
check("interior gap is flaky", classify(S, [1, 3]), ("flaky", None))

# An evidence-free layer is a hole, not a pass, so it must not fake a gap...
check("gap explained by an evidence-free layer is not flaky",
      classify(S, [1, 3], unknown_prs=[2]), ("fixed-higher", 4))

# ...nor stand as the layer where the fix landed.
check("regression: an evidence-free layer cannot witness a fix",
      classify(S, [1, 2], unknown_prs=[3]), ("fixed-higher", 4))
check("all layers above are evidence-free, so nothing witnessed a fix",
      classify(S, [1, 2], unknown_prs=[3, 4, 5]), ("propagating", None))

# Single observation plus an evidence-free layer above is still one observation.
check("one failure with an evidence-free layer above stays unconfirmed",
      classify(S, [2], unknown_prs=[3]), ("unconfirmed", 4))

# --- the two defects the eval runs exposed ---------------------------------
from collect_stack_failures import RETRY_LINE, IDENT_PATH

# A retry-rescued pass must be recognisable from the log line alone. These are the real
# shapes RSpec::Rebound emits; the collector reads them to discount a clearing layer.
for label, line in [
    ("1st Try error", "1st Try error in ./spec/system/item_analytics_spec.rb:190: boom"),
    ("RSpec::Rebound", "RSpec::Rebound: 2nd try ./spec/system/item_analytics_spec.rb:190"),
    ("passed on attempt", "./spec/system/item_analytics_spec.rb:190 — passed on attempt 2"),
]:
    check(f"retry marker recognised: {label}", bool(RETRY_LINE.search(line)), True)

check("a clean pass line is not a retry",
      bool(RETRY_LINE.search("./spec/system/item_analytics_spec.rb:190 passed")), False)

# The identity the collector prints must yield the path:line the log is searched for.
m = IDENT_PATH.search("rspec spec/system/item_analytics_spec.rb:190")
check("identity yields path and line",
      (m.group(1), m.group(2)) if m else None,
      ("spec/system/item_analytics_spec.rb", "190"))
m2 = IDENT_PATH.search("cucumber features/chatbot/parity.feature :: Counts match the page")
check("named cucumber identity yields its feature path",
      m2.group(1) if m2 else None, "features/chatbot/parity.feature")

# Blindness by volume: the rule that replaced name matching, because a skipped sharded
# check keeps its unexpanded workflow template as its name and never matches.
def ran_short(count, stack_counts):
    ordered = sorted(stack_counts)
    median = ordered[len(ordered) // 2]
    return bool(median) and count * 2 < median

check("a layer running far fewer checks than its peers is blind",
      ran_short(19, [19, 79, 80, 84, 86, 88, 88, 88]), True)
check("a layer running a normal number of checks is not blind",
      ran_short(79, [19, 79, 80, 84, 86, 88, 88, 88]), False)

print(f"\n{len(fails)} failure(s)" if fails else "\nall passed")
sys.exit(1 if fails else 0)

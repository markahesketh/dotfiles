#!/usr/bin/env python3
"""Build the failure-attribution matrix for a stacked chain of pull requests.

The point of this script is to answer one question per failing test: *which PR in
the stack introduced it?* Fixing a failure anywhere above its origin means merging
the origin PR on its own still ships the bug.

Two things make that harder than diffing CI result grids by hand:

  * CI shards tests dynamically, so a job name like "Test Ruby (17, 34)" refers to
    different tests on every run. Only the test identity (file:line) is stable.
  * A failure that is absent from a PR above its origin does not always mean a
    flake. It often means a later PR already fixed it, and the fix simply belongs
    further down. Those two cases need opposite actions, so they are classified
    separately here.

Usage:
    collect_stack_failures.py                 # table for the current stack
    collect_stack_failures.py --json          # machine-readable
    collect_stack_failures.py --prs 1,2,3     # explicit bottom-to-top order
"""

import argparse
import json
import re
import subprocess
import sys
from collections import Counter
from concurrent.futures import ThreadPoolExecutor

# Test identity must be stable across the whole stack, and a line number is not:
# any layer that edits the file above a test shifts every line below it, so the same
# scenario appears under two keys with two different origins. Prefer the scenario or
# example NAME, falling back to file:line only when no name is in the log.
#
# Kept deliberately in step with fix-pr-ci/scripts/fetch_failing_specs. If you teach
# one of them a new test framework, teach the other.
NAMED_PATTERNS = [
    # cucumber -p knapsack features/x.feature:17 # Scenario: Counts match the page
    (re.compile(r"cucumber\s+(?:-p\s+\S+\s+)?(features/\S+?):(\d+)\s*#\s*Scenario:\s*(.+?)\s*$", re.M), "cucumber"),
    # rspec ./spec/x_spec.rb:42 # SomeClass does the thing
    (re.compile(r"rspec\s+(?:\./)?(spec/\S+?):(\d+(?::\d+)*)\s*#\s*(.+?)\s*$", re.M), "rspec"),
]
POSITIONAL_PATTERNS = [
    (re.compile(r"rspec\s+(?:\./)?(spec/[^\s:]+):(\d+(?::\d+)*)"), "rspec"),
    (re.compile(r"^\s*#\s+(?:\./)?(spec/[^\s:]+):(\d+)$", re.M), "rspec"),
    (re.compile(r"cucumber\s+(?:-p\s+\S+\s+)?(features/[^\s:]+):(\d+)"), "cucumber"),
    (re.compile(r"^\s*(?:FAIL|✗|×)\s+((?:src|app|test|spec)/\S+\.(?:test|spec)\.[jt]sx?)()", re.M), "js"),
]
ANSI = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")
RUN_URL = re.compile(r"/actions/runs/(\d+)")
INCOMPLETE = {"PENDING", "QUEUED", "IN_PROGRESS", "WAITING", "REQUESTED", None, ""}
FAILED = {"FAILURE", "STARTUP_FAILURE"}
# A cancelled or timed-out run proves nothing either way. Counting it as a failure
# invents red PRs; counting it as a pass invents a layer where the bug was "fixed".
UNKNOWN = {"CANCELLED", "TIMED_OUT"}
# A skipped check is terminal and green-looking, but it executed nothing. Counting it as
# a pass is how a layer that never ran the tests gets read as the layer that fixed them.
SKIPPED = {"SKIPPED", "NEUTRAL"}


def sh(*cmd, check=True):
    p = subprocess.run(cmd, capture_output=True, text=True)
    if p.returncode and check:
        sys.exit(f"Command failed: {' '.join(cmd)}\n{p.stderr}")
    return p.stdout if p.returncode == 0 else ""


def repo_slug():
    return sh("gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner").strip()


def stack_prs():
    """Stack order, bottom to top, from the gh-stack extension."""
    out = sh("gh", "stack", "view", "--json", check=False)
    if not out.strip():
        sys.exit(
            "Could not read the stack. Check one out first, e.g. `gh stack checkout <pr>`,\n"
            "or pass the order explicitly with --prs 111,112,113 (bottom to top)."
        )
    data = json.loads(out)
    prs = [b["pr"]["number"] for b in data.get("branches", []) if b.get("pr")]
    if not prs:
        sys.exit("The stack has no associated PRs yet. Run `gh stack submit --auto` first.")
    return prs


def pr_checks(pr):
    """Return (failed_runs, pending, cancelled, failed_statuses, skipped, executed, all_runs) for one PR.

    Two shapes share this list. A CheckRun reports in `status`/`conclusion`; a commit
    status (StatusContext) reports in `state` and has no run behind it. Reading only
    `conclusion` makes every commit status look unfinished.
    """
    out = sh("gh", "pr", "view", str(pr), "--json", "statusCheckRollup", check=False)
    rollup = (json.loads(out).get("statusCheckRollup") or []) if out.strip() else []
    runs, pending, cancelled, failed_statuses = set(), [], [], []
    skipped, executed, all_runs = [], [], set()
    for check in rollup:
        name = check.get("name") or check.get("context") or "?"
        if check.get("__typename") == "StatusContext":
            # A pending commit status is usually a human gate (required label, review
            # bot, deploy approval) that never resolves itself. Counting it as pending
            # makes "everything has reported" unsatisfiable, so only red ones matter
            # here — and they carry no run, so they cannot yield a test identity.
            if (check.get("state") or "").upper() in {"FAILURE", "ERROR"}:
                failed_statuses.append(name)
            continue
        status = (check.get("status") or "").upper()
        concl = (check.get("conclusion") or "").upper()
        # A check still running has no conclusion yet; SKIPPED/NEUTRAL are terminal.
        if status and status != "COMPLETED" and concl in INCOMPLETE:
            pending.append(name)
            continue
        # `gh pr checks` renders CANCELLED identically to FAILURE, which is how a
        # cancelled run gets mistaken for a broken one.
        if concl in UNKNOWN:
            cancelled.append(name)
            continue
        # A skipped check ran nothing, so it proves nothing. Recorded by name because
        # whether that matters depends on whether the same check ran on other layers.
        if concl in SKIPPED:
            skipped.append(name)
            continue
        m = RUN_URL.search(check.get("detailsUrl") or "")
        if m:
            all_runs.add(m.group(1))
            if concl in FAILED:
                runs.add(m.group(1))
        executed.append(name)
    return sorted(runs), pending, cancelled, failed_statuses, skipped, executed, sorted(all_runs)


def failed_jobs(repo, run_id):
    out = sh("gh", "api", "--paginate", f"repos/{repo}/actions/runs/{run_id}/jobs",
             "-q", '.jobs[] | select(.conclusion == "failure") | .id', check=False)
    return [l.strip() for l in out.splitlines() if l.strip()]


def job_identities(repo, job_id):
    # gh refuses raw API output containing escape sequences, which CI logs always have.
    log = ANSI.sub("", sh("gh", "run", "view", f"--job={job_id}", "--log", "-R", repo, check=False))
    found, named_files = set(), set()
    for pattern, kind in NAMED_PATTERNS:
        for path, _line, name in pattern.findall(log):
            found.add(f"{kind} {path} :: {name.strip()}")
            named_files.add(path)
    # Only fall back to file:line for files where no name was recoverable, so a named
    # scenario never also appears under an unstable positional key.
    for pattern, kind in POSITIONAL_PATTERNS:
        for match in pattern.findall(log):
            path, line = (match + ("",))[:2] if isinstance(match, tuple) else (match, "")
            if path in named_files:
                continue
            found.add(f"{kind} {path}:{line}" if line else f"{kind} {path}")
    return found, bool(log.strip())


# A retry gem re-runs a failed example inside the same job. If a later attempt passes the
# job concludes SUCCESS and the rollup shows nothing unusual, so the layer reads as one
# where the test passed. It is the same error as counting a skipped check as a pass, but
# worse: it manufactures the very boundary that "fixed-higher" and "unconfirmed" are
# derived from, inventing a clearing layer that does not exist.
RETRY_LINE = re.compile(
    r"(?:\d(?:st|nd|rd|th) [Tt]ry error in|RSpec::Rebound|passed on attempt|"
    r"RETRY|retrying|Retrying)", re.I)
# The identity as printed by the collector, e.g. "rspec spec/a_spec.rb:190" or
# "cucumber features/a.feature :: Scenario name".
IDENT_PATH = re.compile(r"((?:spec|features)/\S+?\.(?:rb|feature))(?::(\d+))?")


def run_jobs(repo, run_id):
    """(job_id, job_name) for every job in a run, so callers can filter before reading logs."""
    out = sh("gh", "api", "--paginate", f"repos/{repo}/actions/runs/{run_id}/jobs",
             "-q", r'.jobs[] | "\(.id)\t\(.name)"', check=False)
    rows = []
    for line in out.splitlines():
        if "\t" in line:
            jid, name = line.split("\t", 1)
            rows.append((jid.strip(), name.strip()))
    return rows


# Which jobs could plausibly have run a given test, so a layer with 76 jobs does not need
# 76 log fetches. Keyed off the identity prefix the collector already assigns.
SUITE_JOBS = {
    "rspec": re.compile(r"ruby|rspec", re.I),
    "cucumber": re.compile(r"cucumber", re.I),
    "js": re.compile(r"javascript|jest|vitest", re.I),
}


def job_log(repo, job_id, _cache={}):
    if job_id not in _cache:
        _cache[job_id] = ANSI.sub("", sh("gh", "run", "view", f"--job={job_id}",
                                         "--log", "-R", repo, check=False))
    return _cache[job_id]


def retry_rescued(repo, pr_record, identity, max_jobs=60):
    """Did this PR only pass `identity` because a retry rescued it?

    Scans the layer's own job logs for a line that names the test and marks a retry. Only
    called for the handful of identities that look like they clear at a layer, because the
    logs are expensive and everything else does not depend on them.
    """
    m = IDENT_PATH.search(identity)
    if not m:
        return False
    path, line = m.group(1), m.group(2)
    needle = f"{path}:{line}" if line else path
    suite = SUITE_JOBS.get(identity.split(None, 1)[0].lower())
    jobs = [(j, n) for r in pr_record["all_runs"] for j, n in run_jobs(repo, r)]
    # Truncating an unfiltered list silently drops the shard that matters: a layer can carry
    # 76 jobs and the relevant one be near the end. Narrow by suite first, cap second.
    if suite:
        jobs = [(j, n) for j, n in jobs if suite.search(n)]
    jobs = [j for j, _ in jobs][:max_jobs]
    with ThreadPoolExecutor(max_workers=8) as pool:
        for log in pool.map(lambda j: job_log(repo, j), jobs):
            for ln in log.splitlines():
                if needle in ln and RETRY_LINE.search(ln):
                    return True
    return False


def collect(repo, pr):
    runs, pending, cancelled, failed_statuses, skipped, executed, all_runs = pr_checks(pr)
    jobs = [j for r in runs for j in failed_jobs(repo, r)]
    identities, parsed_any = set(), False
    for job in jobs:
        ids, had_log = job_identities(repo, job)
        identities |= ids
        parsed_any = parsed_any or had_log
    return {
        "pr": pr,
        "pending": pending,
        "cancelled": cancelled,
        "failed_statuses": failed_statuses,
        "skipped": skipped,
        "executed": executed,
        "all_runs": all_runs,
        # Without a completed run this PR is evidence-free: it can neither confirm a
        # failure nor witness a fix.
        "unknown": bool(cancelled) and not identities,
        "failed_runs": runs,
        "failed_jobs": len(jobs),
        # A red PR with failed jobs but no parsed test identity is a build/lint/setup
        # failure. Silently reporting "no failures" for it would be a lie. But when the
        # run was also cancelled, "we don't know yet" is the honest label, not "broken".
        "unparsed_failure": bool(jobs) and not identities and not cancelled,
        "identities": sorted(identities),
    }


def classify(order, failing_prs, unknown_prs=()):
    """Given the stack order and the PRs where one test failed, name the pattern.

    A genuine regression appears at its origin and never clears on its own. Where it
    genuinely clears, something above it fixed the problem and that fix is sitting in
    the wrong layer. Interior holes mean the result is not reproducible run to run.

    PRs with no completed run, and PRs that skipped a check other layers ran, are holes in
    the evidence rather than observations: they can neither break a contiguous run nor
    stand as the layer where a fix landed.
    """
    unknown_i = {order.index(p) for p in unknown_prs}
    idx = sorted(order.index(p) for p in failing_prs)
    origin_i, last_i, top_i = idx[0], idx[-1], len(order) - 1

    gaps = [i for i in range(origin_i, last_i + 1) if i not in idx and i not in unknown_i]
    if gaps:
        return "flaky", None

    # Walk past layers that never reported to find the first that truly went green.
    nxt = last_i + 1
    while nxt <= top_i and nxt in unknown_i:
        nxt += 1
    if nxt > top_i:
        return "propagating", None

    # "fixed-higher" is a strong claim: it says a fix already exists above and should be
    # moved down, so do not write a new one. A single failing layer with green above
    # cannot support it — one red result is equally consistent with a flake that happened
    # not to recur. Two consecutive failures establish the failure is real; only then does
    # the layer where it clears mean something.
    if len(idx) < 2:
        return "unconfirmed", order[nxt]
    return "fixed-higher", order[nxt]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--prs", help="Comma-separated PR numbers, bottom to top")
    ap.add_argument("--no-retry-check", action="store_true",
                    help="Skip reading the clearing layer's logs for a retry-rescued pass")
    ap.add_argument("--allow-incomplete", action="store_true",
                    help="Attribute anyway while runs are still going (results may misfile)")
    args = ap.parse_args()

    repo = repo_slug()
    order = [int(x) for x in args.prs.split(",")] if args.prs else stack_prs()
    print(f"Repo {repo} — stack bottom to top: {order}", file=sys.stderr)

    with ThreadPoolExecutor(max_workers=8) as pool:
        results = list(pool.map(lambda p: collect(repo, p), order))
    by_pr = {r["pr"]: r for r in results}

    incomplete = {r["pr"]: r["pending"] for r in results if r["pending"]}
    if incomplete and not args.allow_incomplete:
        print("\nCI is still running. Attributing now would misfile any failure whose true", file=sys.stderr)
        print("origin has not reported yet:\n", file=sys.stderr)
        for pr, names in incomplete.items():
            print(f"  PR #{pr}: {len(names)} check(s) pending — e.g. {', '.join(names[:3])}", file=sys.stderr)
        print("\nWait for them, or pass --allow-incomplete to proceed anyway.", file=sys.stderr)
        if not args.json:
            sys.exit(2)

    # Two ways a layer can be blind, because neither alone is enough.
    #
    # By name: a check the stack runs routinely, skipped here. This catches unsharded
    # checks precisely. It has to be *routine* — a gate that fires on one layer by design,
    # like "Check staging PR labels" on the layer targeting the trunk, is a structural fact
    # about stacks rather than a hole in the evidence.
    #
    # By count: how many checks this layer ran against what its peers ran. Name matching
    # cannot see sharded checks at all, because a skipped matrix job keeps its unexpanded
    # workflow template as its name — `Test Ruby`, or literally
    # `${{ ... }} (${{ matrix.ci_node_index }}, ...)` — while the layers that ran it report
    # `Test Cucumber (0, 26)` and so on. The checks that carry the test evidence are exactly
    # the ones the name rule misses, which is the sharding trap this skill warns about,
    # sprung on its own collector. A raw count needs no names and cannot be fooled by them.
    runs_per_name = Counter(n for r in results for n in set(r["executed"]))
    routine = {n for n, c in runs_per_name.items() if c * 2 > len(results)}
    counts = sorted(len(r["executed"]) for r in results)
    median = counts[len(counts) // 2] if counts else 0
    for r in results:
        # A name can appear twice on one PR when a check was re-run, skipped once and
        # executed once. Only a check that never executed *here* leaves this layer blind.
        r["blind_to"] = sorted((set(r["skipped"]) & routine) - set(r["executed"]))
        r["ran_count"] = len(r["executed"])
        r["ran_short"] = bool(median) and r["ran_count"] * 2 < median
    unknown_prs = [r["pr"] for r in results if r["unknown"] or r["blind_to"] or r["ran_short"]]

    tests = {}
    for r in results:
        for ident in r["identities"]:
            tests.setdefault(ident, []).append(r["pr"])

    rows = []
    for ident, prs in sorted(tests.items()):
        kind, fixed_at = classify(order, prs, unknown_prs)
        rescued = False
        # Only worth the log fetch where a clearing layer is what the verdict rests on.
        if fixed_at and not args.no_retry_check:
            rescued = retry_rescued(repo, by_pr[fixed_at], ident)
            if rescued:
                # That layer did not clear it, so re-ask with the layer discounted.
                kind, fixed_at = classify(order, prs, list(unknown_prs) + [fixed_at])
        rows.append({
            "test": ident,
            "failing_prs": prs,
            "origin_pr": min(prs, key=order.index),
            "pattern": kind,
            "fix_already_at_pr": fixed_at,
            "retry_rescued_above": rescued,
        })

    unparsed = [r["pr"] for r in results if r["unparsed_failure"]]

    if args.json:
        print(json.dumps({
            "repo": repo, "stack": order, "tests": rows,
            "incomplete": incomplete, "unparsed_failure_prs": unparsed,
            "unknown_prs": unknown_prs,
            "per_pr": {str(p): by_pr[p] for p in order},
        }, indent=2))
        return

    if not rows and not unparsed:
        print("\nNo test failures found across the stack.")
        return

    print(f"\n{'TEST':<62} {'ORIGIN':>7}  PATTERN")
    print("-" * 96)
    for row in rows:
        at = row["fix_already_at_pr"]
        note = ""
        if at and row["pattern"] == "fixed-higher":
            note = f"  (already fixed at #{at})"
        elif at:
            note = f"  (clears at #{at}, on one observation only)"
        if row["retry_rescued_above"]:
            note += "  [a layer above only passed on a retry]"
        print(f"{row['test']:<62} {'#' + str(row['origin_pr']):>7}  {row['pattern']}{note}")

    print("\nBy origin PR — one agent per PR, never one per failure:")
    for pr in order:
        mine = [r for r in rows if r["origin_pr"] == pr]
        if mine:
            print(f"  #{pr}: {len(mine)} failure(s) originate here")
            for r in mine:
                print(f"      - {r['test']}  [{r['pattern']}]")

    if unparsed:
        print(f"\nRed with no parseable test identity (build/lint/setup): {unparsed}")
        print("Inspect these directly with `gh pr checks <pr>` — they are not test failures.")

    red_statuses = {p: by_pr[p]["failed_statuses"] for p in order if by_pr[p]["failed_statuses"]}
    if red_statuses:
        print("\nRed commit statuses, which have no workflow run and so no test identity:")
        for pr, names in red_statuses.items():
            print(f"  #{pr}: {', '.join(names)}")

    no_run = [p for p in order if by_pr[p]["unknown"]]
    if no_run:
        print(f"\nNo completed run, so no evidence either way: {no_run}")
        print("Their runs were cancelled or timed out. `gh pr checks` prints those the same")
        print("as a failure. They need a re-run, not a fix, and they cannot witness a fix.")

    blind = [p for p in order if by_pr[p]["blind_to"] or by_pr[p]["ran_short"]]
    if blind:
        print("\nRan too little to witness a fix:")
        for pr in blind:
            bits = []
            if by_pr[pr]["ran_short"]:
                bits.append(f"ran {by_pr[pr]['ran_count']} checks against a stack median of {median}")
            if by_pr[pr]["blind_to"]:
                bits.append(f"skipped {', '.join(by_pr[pr]['blind_to'][:4])}")
            print(f"  #{pr}: {'; '.join(bits)}")
        print("A skipped check is terminal and looks green, but it executed nothing.")

    print("\nPatterns: propagating = real regression, fix at origin. "
          "fixed-higher = the fix exists above,\nmove it down to the origin. "
          "flaky = non-contiguous, reproduce before believing it.\n"
          "unconfirmed = failed on one layer only and cleared above, which one red run "
          "cannot\ntell apart from a flake. Re-run it or read the diff before you move "
          "anything.")
    if any(r["retry_rescued_above"] for r in rows):
        print("\nA layer above passed one of these only because a retry rescued it, so it was")
        print("discounted as a witness. A retried pass and a clean pass look identical in the")
        print("check list; the difference is only in the job log.")

    print("\nThis is a hypothesis, not a verdict. A test missing from a PR's failures may"
          "\nhave passed, or may not have run in that shard — identical here, opposite"
          "\nmeanings. Confirm the origin with `git grep` / `git log -S` before fixing.")


if __name__ == "__main__":
    main()

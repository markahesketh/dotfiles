#!/usr/bin/env python3
"""Post a single GitHub PR review (summary + inline comments) via `gh api`.

Only ever call this after the user has explicitly confirmed the exact
wording of the summary and every inline comment. This script does not
ask for confirmation itself -- that must already have happened.

Usage:
    post_review.py [--dry-run] <pr-number-or-url> <draft.json>

--dry-run validates the draft and prints the payload without posting.

draft.json shape:
{
  "head_commit": "<sha from gather_pr_context.py>",
  "body": "brief summary shown at the top of the review",
  "event": "REQUEST_CHANGES" | "COMMENT" | "APPROVE",
  "comments": [
    {"path": "src/foo.ts", "line": 42, "body": "..."},
    {"path": "src/bar.ts", "line": 7, "side": "LEFT", "body": "..."}
  ]
}

Before posting, the script checks that:
  - the PR head still matches head_commit (the author has not pushed since
    the diff was read, which would move the line numbers)
  - every comment points at a line that is in the diff (GitHub rejects the
    whole review with 422 otherwise)
"""
import json
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from pr_common import gh, resolve_pr, validate_comments


def main():
    args = sys.argv[1:]
    dry_run = "--dry-run" in args
    args = [a for a in args if a != "--dry-run"]
    if len(args) != 2:
        print(__doc__)
        sys.exit(1)

    pr_ref, draft_path = args

    with open(draft_path) as f:
        draft = json.load(f)

    missing = [k for k in ("head_commit", "body", "event", "comments") if k not in draft]
    if missing:
        raise SystemExit(f"draft.json missing required keys: {', '.join(missing)}")
    if draft["event"] not in ("REQUEST_CHANGES", "COMMENT", "APPROVE"):
        raise SystemExit(f"event must be REQUEST_CHANGES, COMMENT or APPROVE, got {draft['event']!r}")

    repo, number, head = resolve_pr(pr_ref)
    if head != draft["head_commit"]:
        raise SystemExit(
            f"PR head is now {head[:10]}, draft was written against {draft['head_commit'][:10]}. "
            "The author has pushed since the diff was read. Re-run gather_pr_context.py and redraft."
        )

    diff = gh(["pr", "diff", pr_ref, "--repo", repo]).stdout
    problems = validate_comments(draft["comments"], diff)
    if problems:
        raise SystemExit("draft has invalid comment anchors:\n  " + "\n  ".join(problems))

    payload = {
        "commit_id": head,
        "body": draft["body"],
        "event": draft["event"],
        "comments": draft["comments"],
    }
    endpoint = f"repos/{repo}/pulls/{number}/reviews"

    if dry_run:
        print(f"DRY RUN: would POST {endpoint}")
        print(json.dumps(payload, indent=2))
        return

    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as tmp:
        json.dump(payload, tmp)
        tmp_path = tmp.name

    result = gh(["api", endpoint, "--input", tmp_path], check=False)
    if result.returncode != 0:
        print(result.stdout)
        print(result.stderr, file=sys.stderr)
        sys.exit(result.returncode)

    review = json.loads(result.stdout)
    print(f"Posted review: {review.get('html_url', '(no url returned)')}")


if __name__ == "__main__":
    main()

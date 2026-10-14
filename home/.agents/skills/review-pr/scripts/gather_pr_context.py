#!/usr/bin/env python3
"""Gather everything needed to review a PR in one consistent shot.

Usage:
    gather_pr_context.py <pr-number-or-url>

Writes two files under /tmp/review-pr/<owner>-<repo>-<number>/:
    context.json  metadata, changed files, and everything already said about
                  the PR (reviews with verdicts, inline comments, issue comments)
    pr.diff       the full unified diff

Prints context.json to stdout (it is small) and the path of pr.diff.
Read the diff from the file. Reading the existing comments first avoids
repeating a point someone else already made.
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from pr_common import gh, gh_api_paginated, gh_json, resolve_pr


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)

    pr_ref = sys.argv[1]
    repo, number, head = resolve_pr(pr_ref)
    api = f"repos/{repo}/pulls/{number}"

    pr = gh_json(["pr", "view", pr_ref, "--json", "title,body,url,author,files"])
    viewer = gh_json(["api", "user"])["login"]
    diff = gh(["pr", "diff", pr_ref, "--repo", repo]).stdout

    reviews = gh_api_paginated(f"{api}/reviews")
    review_comments = gh_api_paginated(f"{api}/comments")
    issue_comments = gh_api_paginated(f"repos/{repo}/issues/{number}/comments")

    out_dir = Path("/tmp/review-pr") / f"{repo.replace('/', '-')}-{number}"
    out_dir.mkdir(parents=True, exist_ok=True)
    diff_path = out_dir / "pr.diff"
    diff_path.write_text(diff)

    context = {
        "repo": repo,
        "number": number,
        "title": pr["title"],
        "body": pr["body"],
        "url": pr["url"],
        "author": pr["author"]["login"],
        "viewer_is_author": pr["author"]["login"] == viewer,
        "head_commit": head,
        "files": pr["files"],
        "diff_path": str(diff_path),
        "existing_reviews": [
            {
                "author": r["user"]["login"],
                "state": r["state"],
                "body": r["body"],
                "submitted_at": r.get("submitted_at"),
            }
            for r in reviews
        ],
        "existing_review_comments": [
            {
                "author": c["user"]["login"],
                "path": c["path"],
                "line": c.get("line"),
                "body": c["body"],
            }
            for c in review_comments
        ],
        "existing_issue_comments": [
            {"author": c["user"]["login"], "body": c["body"]} for c in issue_comments
        ],
    }
    (out_dir / "context.json").write_text(json.dumps(context, indent=2))
    print(json.dumps(context, indent=2))


if __name__ == "__main__":
    main()

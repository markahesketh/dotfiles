"""Shared helpers for the review-pr scripts."""
import json
import re
import subprocess
from collections import defaultdict

PR_URL_RE = re.compile(r"github\.com/([^/]+)/([^/]+)/pull/(\d+)")


def gh(args, check=True):
    result = subprocess.run(["gh", *args], capture_output=True, text=True)
    if check and result.returncode != 0:
        raise SystemExit(f"gh {' '.join(args)} failed:\n{result.stderr.strip()}")
    return result


def gh_json(args):
    return json.loads(gh(args).stdout)


def resolve_pr(pr_ref):
    """Resolve a PR number or URL to (owner/repo, number, head_sha).

    The repo comes from the PR's own URL, never from the current directory,
    so a URL pointing at another repo resolves to that repo.
    """
    pr = gh_json(["pr", "view", pr_ref, "--json", "url,number,headRefOid"])
    m = PR_URL_RE.search(pr["url"])
    if not m:
        raise SystemExit(f"could not parse repo from PR url: {pr['url']}")
    repo = f"{m.group(1)}/{m.group(2)}"
    return repo, pr["number"], pr["headRefOid"]


def gh_api_paginated(path):
    out = gh(["api", "--paginate", "--slurp", path]).stdout
    pages = json.loads(out)
    return [item for page in pages for item in page]


HUNK_RE = re.compile(r"^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@")


def commentable_lines(diff_text):
    """Return {path: {"RIGHT": set(lines), "LEFT": set(lines)}} from a unified diff.

    GitHub only accepts inline review comments on lines that appear in the
    diff. RIGHT = lines present in the new file (added + context), LEFT =
    lines present in the old file (deleted + context).
    """
    result = defaultdict(lambda: {"RIGHT": set(), "LEFT": set()})
    path = None
    old = new = None
    for raw in diff_text.splitlines():
        if raw.startswith("diff --git"):
            path = None
            old = new = None
            continue
        if raw.startswith("+++ "):
            target = raw[4:].strip()
            path = None if target == "/dev/null" else target[2:] if target.startswith("b/") else target
            continue
        if raw.startswith("--- "):
            continue
        m = HUNK_RE.match(raw)
        if m:
            old, new = int(m.group(1)), int(m.group(2))
            continue
        if path is None or old is None:
            continue
        if raw.startswith("\\"):
            continue
        if raw.startswith("+"):
            result[path]["RIGHT"].add(new)
            new += 1
        elif raw.startswith("-"):
            result[path]["LEFT"].add(old)
            old += 1
        else:
            result[path]["RIGHT"].add(new)
            result[path]["LEFT"].add(old)
            old += 1
            new += 1
    return result


def validate_comments(comments, diff_text):
    """Return a list of human-readable problems with comment anchors."""
    lines = commentable_lines(diff_text)
    problems = []
    for i, c in enumerate(comments):
        for key in ("path", "line", "body"):
            if key not in c:
                problems.append(f"comment {i}: missing '{key}'")
        if problems:
            continue
        side = c.get("side", "RIGHT")
        if side not in ("RIGHT", "LEFT"):
            problems.append(f"comment {i}: side must be RIGHT or LEFT, got {side!r}")
            continue
        if c["path"] not in lines:
            problems.append(f"comment {i}: {c['path']} is not in the diff")
        elif c["line"] not in lines[c["path"]][side]:
            problems.append(
                f"comment {i}: {c['path']}:{c['line']} ({side}) is not a line in the diff"
            )
    return problems

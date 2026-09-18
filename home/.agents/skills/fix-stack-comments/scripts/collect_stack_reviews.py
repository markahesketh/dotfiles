#!/usr/bin/env python3
"""Attribute every piece of outstanding review feedback in a stacked PR chain to the layer that owns the code.

Reviewers leave feedback in three different GitHub objects, and they behave so
differently that treating them alike loses most of it:

  * **Review threads** are inline and resolvable. They carry a file and a line, so the
    owning layer can be found by blaming that line.
  * **Review bodies** (the summary attached to an APPROVED / CHANGES_REQUESTED review)
    have no anchor and cannot be resolved.
  * **Issue comments** - the plain PR conversation - likewise have no anchor and cannot
    be resolved. In practice this is where the most substantial review often lands: a
    numbered list of several distinct findings, each about a different file.

That last case is why this script exists in this shape. One comment can hold N findings
belonging to N different layers, so the unit of work is a **finding**, not a comment,
and "address the comments on this PR" is the wrong frame entirely.

Attribution, in order of sharpness:

  1. An anchored thread: blame the line, map the commit to a layer.
  2. An unanchored finding: run `git log -S` over the stack range for each distinctive
     code fragment the reviewer quoted. This beats file-level attribution, which is
     often ambiguous - a spec file touched by two layers says nothing about which of
     them introduced the example being complained about.
  3. Failing that: which layers' diffs touch the files named in the prose.

Usage:
    collect_stack_reviews.py                 # table for the current stack
    collect_stack_reviews.py --json          # machine-readable
    collect_stack_reviews.py --prs 1,2,3     # explicit bottom-to-top order
    collect_stack_reviews.py --include-resolved
"""

import argparse
import json
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

QUERY = """
query($owner:String!,$repo:String!,$pr:Int!,$cursor:String){
  repository(owner:$owner,name:$repo){
    pullRequest(number:$pr){
      author{login}
      reviewThreads(first:100, after:$cursor){
        pageInfo{ hasNextPage endCursor }
        nodes{
          id isResolved isOutdated subjectType path line originalLine
          comments(first:1){ totalCount nodes{ author{login} body url } }
        }
      }
      reviews(first:50){ nodes{ id state author{login} body url submittedAt } }
      comments(first:50){ nodes{ id author{login} body url createdAt } }
    }
  }
}
"""

# Reviewer prose carries volatile detail - line numbers, links, markdown - that differs
# between two reports of the same underlying finding. Strip it so the same finding on
# three layers collapses to one fingerprint. Backticks go but their contents stay: one
# reviewer writes `@site` where another writes @site, and the identifier is the part
# that tells you it is the same finding.
NOISE = re.compile(r"(\b\d+\b|https?://\S+|[`_*~#>|\[\]()-])")

# Both AI reviewers open with a banner rather than the finding: the repo's own reviewers
# emit `<sub>Test reliability</sub>`, CodeRabbit a row of pipe-separated severity badges.
# The banner varies while the claim beneath it does not, so keying on it makes one
# finding look like several.
BANNER = re.compile(
    r"^(?:<sub>.*</sub>"
    r"|(?:[_*]+[^_*|]+[_*]+\s*\|\s*)+[_*]+[^_*|]+[_*]+"
    r"|[\W\d_]+)$",
    re.S,
)

# Bot scaffolding, not review feedback. CodeRabbit posts an identical status comment on
# every PR in the stack; counted as findings they outnumber the real ones and, being
# byte-identical, they dominate the duplicate report too.
AUTOGEN = re.compile(r"auto-generated comment|<!--\s*tips_start|This is an auto-generated"
                     r"|configured for manual code reviews|\*\*Merge Risk:\*\*"
                     r"|Review limit reached|Review Change Stack|Review rate limited")

# CodeRabbit folds most of a comment into <details> blocks. A block's <summary> says
# which kind it is: findings posted "Outside the diff" or as nitpicks sit under a
# severity badge and never appear as threads, so they have to be kept and unwrapped;
# evidence, AI prompts and review metadata are dropped. Unknown summaries are kept -
# a stray line of noise is cheaper than a lost finding.
DETAILS = re.compile(r"<details>\s*(?:<summary>(.*?)</summary>)?(.*?)</details>", re.S)
DROP_DETAILS = re.compile(
    r"Prompt for|Review info|Run configuration|Autofix|Supported by static analysis"
    r"|Script executed|Commits|Files (?:selected|ignored|skipped|not)|Knowledge Base"
    r"|Walkthrough|Review details|Included review availability|Recent review"
    r"|Additional context|Comments suppressed|Tips|Suggested reviewers|Pre-merge checks"
    r"|Estimated code review effort|Sequence Diagram|Possibly related|Poem", re.I)
HTML = re.compile(r"<!--.*?-->|</?(?:blockquote|sub|details|summary)>|<a href=.*?</a>|<img [^>]*>",
                  re.S)

# Lines that a review body or PR comment is made of when it carries no finding: the
# per-review status line, the walkthrough's risk badge, the usage-limit warning.
SCAFFOLD_LINE = re.compile(
    r"^(?:\*\*Actionable comments posted:|\*\*Included review availability:"
    r"|\*\*Merge Risk:|\*\*Priority:|Review limit reached"
    r"|Or wait \d+ minutes|Run on-demand review|On-demand reviews|Check out review usage"
    r"|Comment `@coderabbitai|Fix all unresolved|Push a commit to this branch"
    r"|Create a new PR with the fixes|\[!WARNING\]|---+$|[-*] \[ \]|>\s*$)")


def strip_noise(body):
    text = body or ""
    while True:
        m = DETAILS.search(text)
        if not m:
            break
        summary, inner = (m.group(1) or ""), m.group(2)
        text = text[:m.start()] + ("" if DROP_DETAILS.search(summary) else inner) + text[m.end():]
    text = HTML.sub("", text)
    return re.sub(r"\n{3,}", "\n\n", text).strip()


def is_scaffold(body):
    """True when a stripped body says nothing a reviewer would want acted on."""
    if not body or AUTOGEN.search(body):
        return True
    lines = [ln.strip().lstrip("> ").strip() for ln in body.splitlines()]
    return all(not ln or SCAFFOLD_LINE.match(ln) for ln in lines)


# A numbered list is how a reviewer packs several independent findings into one comment.
# Splitting on it is what turns "2 comments" into the 6 separate decisions it really is.
NUMBERED = re.compile(r"^\s{0,3}(\d{1,2})[.)]\s+", re.M)
BULLETED = re.compile(r"^\s{0,3}[-*+]\s+", re.M)

PATH = re.compile(
    r"\b((?:app|spec|features|lib|config|db|script|evals|dv-cli|docs|bin|\.github)"
    r"/[\w./@-]+\.\w{1,6})\b"
)
FRAGMENT = re.compile(r"`([^`\n]{4,80})`|\"([^\"\n]{8,120})\"")

# A fragment that appears in many commits is common vocabulary, not a fingerprint of the
# code under discussion, so it cannot point at one layer.
MAX_PICKAXE_COMMITS = 4


def sh(*cmd, check=True):
    p = subprocess.run(cmd, capture_output=True, text=True)
    if p.returncode and check:
        sys.exit(f"Command failed: {' '.join(cmd)}\n{p.stderr}")
    return p.stdout if p.returncode == 0 else ""


def repo_slug():
    return sh("gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner").strip()


def stack_layers(explicit=None):
    """Layers bottom to top as (pr, branch, base_sha), from the gh-stack extension."""
    out = sh("gh", "stack", "view", "--json", check=False)
    if not out.strip():
        sys.exit(
            "Could not read the stack. Check one out first, e.g. `gh stack checkout <pr>`,\n"
            "or pass the order explicitly with --prs 111,112,113 (bottom to top)."
        )
    data = json.loads(out)
    layers = [(b["pr"]["number"], b["name"], b.get("base"))
              for b in data.get("branches", []) if b.get("pr")]
    if not layers:
        sys.exit("The stack has no associated PRs yet. Run `gh stack submit --auto` first.")
    if explicit:
        want = [int(x) for x in explicit.split(",")]
        by_pr = {pr: (pr, br, base) for pr, br, base in layers}
        missing = [p for p in want if p not in by_pr]
        if missing:
            sys.exit(f"PRs not in this stack: {missing}")
        layers = [by_pr[p] for p in want]
    return layers


def paragraphs(body):
    return [p.strip() for p in (body or "").split("\n\n") if p.strip() and not BANNER.match(p)]


def claim(body):
    """The sentence that states the finding, for display.

    Reviewers open with boilerplate - a banner, or a paragraph explaining where the list
    came from and that nothing blocks. Prefer a paragraph naming a file: that preamble
    quotes identifiers too, so a backtick alone does not distinguish it, but a finding
    almost always says which file it is about.
    """
    paras = paragraphs(body)
    if not paras:
        return body or ""
    return next((p for p in paras if PATH.search(p)),
                next((p for p in paras if "`" in p), paras[0]))


def fingerprint(body):
    """Key for deciding two findings are the same finding raised twice.

    Keyed on the finding sentence, not the whole body: a reviewer running the same
    checklist over eight PRs repeats their preamble verbatim, and any key that includes
    it calls all eight duplicates of each other - telling you to fix once what are
    really eight separate findings.
    """
    text = NOISE.sub(" ", claim(body)[:600]).lower()
    return " ".join(text.split())[:300]


def split_findings(body):
    """One unanchored comment, split into the separate findings it actually contains.

    Everything before the first list marker is preamble - the reviewer explaining where
    the list came from and how binding it is - which is context for all of them rather
    than a finding of its own.
    """
    marks = list(NUMBERED.finditer(body)) or list(BULLETED.finditer(body))
    if len(marks) < 2:
        return [body.strip()]
    out = []
    for i, mk in enumerate(marks):
        end = marks[i + 1].start() if i + 1 < len(marks) else len(body)
        chunk = body[mk.start():end].strip()
        if chunk:
            out.append(chunk)
    return out


def fetch(repo, pr, include_resolved, include_answered=False):
    owner, name = repo.split("/")
    threads, cursor = [], None
    reviews = comments = None
    author = None
    while True:
        cmd = ["gh", "api", "graphql", "-f", f"query={QUERY}",
               "-F", f"owner={owner}", "-F", f"repo={name}", "-F", f"pr={pr}"]
        if cursor:
            cmd += ["-F", f"cursor={cursor}"]
        out = sh(*cmd, check=False)
        if not out.strip():
            break
        payload = json.loads(out).get("data", {}).get("repository", {}).get("pullRequest") or {}
        author = ((payload.get("author") or {}).get("login")) or author
        if reviews is None:
            reviews = (payload.get("reviews") or {}).get("nodes") or []
            comments = (payload.get("comments") or {}).get("nodes") or []
        block = payload.get("reviewThreads") or {}
        threads += block.get("nodes") or []
        page = block.get("pageInfo") or {}
        if not page.get("hasNextPage"):
            break
        cursor = page["endCursor"]

    items = []
    for t in threads:
        if t.get("isResolved") and not include_resolved:
            continue
        first = ((t.get("comments") or {}).get("nodes") or [{}])[0]
        items.append({
            "kind": "thread", "id": t["id"], "pr": pr, "resolvable": True,
            "resolved": bool(t.get("isResolved")), "outdated": bool(t.get("isOutdated")),
            "path": t.get("path"), "line": t.get("line"),
            "original_line": t.get("originalLine"),
            "author": ((first.get("author") or {}).get("login")) or "?",
            "body": strip_noise(first.get("body")), "url": first.get("url"),
        })

    # Review bodies and issue comments have no anchor and no resolve mutation, so
    # "outstanding" cannot be read off a flag the way it can for a thread. The only
    # signal that one has been dealt with is the PR author posting after it: the
    # fix-pr-comments loop answers each with one PR comment, so anything older than
    # the author's latest comment was seen last round. Skipped unless asked for.
    answered_before = last_author_comment_at(comments or [], author)
    for r in reviews or []:
        body = strip_noise(r.get("body"))
        if is_scaffold(body):
            continue
        answered = is_answered(r.get("submittedAt"), answered_before)
        if answered and not include_answered:
            continue
        for f in split_findings(body):
            items.append({
                "kind": "review-body", "id": r["id"], "pr": pr, "resolvable": False,
                "resolved": False, "answered": answered, "outdated": False,
                "path": None, "line": None,
                "original_line": None, "state": r.get("state"),
                "author": ((r.get("author") or {}).get("login")) or "?",
                "body": f, "url": r.get("url"),
            })
    for c in comments or []:
        body = strip_noise(c.get("body"))
        login = ((c.get("author") or {}).get("login")) or "?"
        if is_scaffold(body) or login == author:
            continue
        answered = is_answered(c.get("createdAt"), answered_before)
        if answered and not include_answered:
            continue
        for f in split_findings(body):
            items.append({
                "kind": "issue-comment", "id": c["id"], "pr": pr, "resolvable": False,
                "resolved": False, "answered": answered, "outdated": False,
                "path": None, "line": None,
                "original_line": None,
                "author": login, "body": f, "url": c.get("url"),
            })
    return items


def last_author_comment_at(comments, author):
    """ISO timestamp of the PR author's newest issue comment, or None."""
    times = [c.get("createdAt") for c in comments
             if ((c.get("author") or {}).get("login")) == author and c.get("createdAt")]
    return max(times) if times else None


def is_answered(posted_at, answered_before):
    # GitHub timestamps are ISO-8601 UTC with a fixed layout, so string order is time order.
    return bool(posted_at and answered_before and posted_at < answered_before)


def commit_owners(layers):
    """Map every commit sha in the stack to the PR whose layer introduced it."""
    owners = {}
    for pr, branch, base in layers:
        if not base:
            continue
        for sha in sh("git", "rev-list", f"{base}..{branch}", check=False).split():
            owners[sha] = pr
    return owners


def files_touched(layers):
    touched = {}
    for pr, branch, base in layers:
        if not base:
            continue
        for f in sh("git", "diff", "--name-only", f"{base}..{branch}", check=False).split():
            touched.setdefault(f, []).append(pr)
    return touched


def blame_line(branch, path, line):
    out = sh("git", "blame", "-L", f"{line},{line}", "--porcelain", branch, "--", path, check=False)
    return out.split(None, 1)[0] if out.strip() else None


class Pickaxe:
    def __init__(self, rng, owners, order):
        self.rng, self.owners, self.order, self.cache = rng, owners, order, {}

    def layers_for(self, needle):
        if needle not in self.cache:
            shas = sh("git", "log", "-S", needle, "--format=%H", self.rng, check=False).split()
            if not shas or len(shas) > MAX_PICKAXE_COMMITS:
                self.cache[needle] = []
            else:
                hits = {self.owners[s] for s in shas if s in self.owners}
                self.cache[needle] = sorted(hits, key=self.order.index)
        return self.cache[needle]


def attribute_unanchored(item, pickaxe, touched, order):
    frags = [a or b for a, b in FRAGMENT.findall(item["body"])]
    frags = sorted({f.strip() for f in frags if len(f.strip()) >= 4}, key=len, reverse=True)[:6]
    votes, evidence = {}, []
    for f in frags:
        for pr in pickaxe.layers_for(f):
            votes[pr] = votes.get(pr, 0) + 1
            evidence.append((f[:40], pr))
    if votes:
        best = sorted(votes, key=lambda p: (-votes[p], order.index(p)))
        item["candidates"] = best
        item["evidence"] = evidence[:4]
        if len(best) == 1 or votes[best[0]] > votes[best[1]]:
            item["owner_pr"], item["owner_reason"] = best[0], "quoted code traced to one layer"
            return
        # Several layers touched the quoted code. Two independent signals can still settle
        # it: the lowest candidate is where origin-fixing has to land, and the PR it was
        # raised on is the diff the reviewer was actually reading. When those agree there
        # is nothing left for a human to weigh up.
        lowest = min(best, key=order.index)
        if lowest == item["pr"]:
            item["owner_pr"] = lowest
            item["owner_reason"] = "lowest candidate, and the PR it was raised on"
        else:
            item["owner_reason"] = "quoted code traces to several layers"
        return
    paths = sorted(set(PATH.findall(item["body"])))
    item["paths"] = paths
    cands = sorted({p for f in paths for p in touched.get(f, [])}, key=order.index)
    item["candidates"] = cands
    item["owner_pr"] = cands[0] if len(cands) == 1 else None
    item["owner_reason"] = (
        "only layer touching the named file" if len(cands) == 1
        else "several layers touch the named files" if cands
        else "no quoted code and no named file in the stack"
    )


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--prs", help="Comma-separated PR numbers, bottom to top")
    ap.add_argument("--include-resolved", action="store_true")
    ap.add_argument("--include-answered", action="store_true",
                    help="Also list review bodies and issue comments older than the PR "
                         "author's latest comment on that PR")
    args = ap.parse_args()

    repo = repo_slug()
    layers = stack_layers(args.prs)
    order = [pr for pr, _, _ in layers]
    branch_of = {pr: br for pr, br, _ in layers}
    print(f"Repo {repo} — stack bottom to top: {order}", file=sys.stderr)

    missing = [br for _, br, _ in layers
               if not sh("git", "rev-parse", "--verify", br, check=False).strip()]
    if missing:
        print(f"\nBranches not present locally: {missing}", file=sys.stderr)
        print("Attribution needs them. Run `git fetch --all` or `gh stack checkout <pr>`.",
              file=sys.stderr)
        sys.exit(2)

    owners = commit_owners(layers)
    touched = files_touched(layers)
    rng = f"{layers[0][2]}..{layers[-1][1]}"
    pickaxe = Pickaxe(rng, owners, order)

    with ThreadPoolExecutor(max_workers=8) as pool:
        items = [i for batch in pool.map(lambda p: fetch(repo, p, args.include_resolved, args.include_answered), order)
                 for i in batch]

    for it in items:
        it.setdefault("owner_pr", None)
        it.setdefault("owner_reason", "")
        if it["kind"] == "thread":
            if it["outdated"] or not it["line"] or not it["path"]:
                it["owner_reason"] = "no live anchor"
                continue
            sha = blame_line(branch_of[it["pr"]], it["path"], it["line"])
            if not sha:
                it["owner_reason"] = "blame failed"
                continue
            it["blame_sha"] = sha[:10]
            if sha in owners:
                it["owner_pr"] = owners[sha]
                it["owner_reason"] = ("posted-on layer" if owners[sha] == it["pr"]
                                      else "lower layer owns the line")
            else:
                it["owner_reason"] = "trunk owns the line"
        else:
            attribute_unanchored(it, pickaxe, touched, order)

    groups = {}
    for it in items:
        groups.setdefault(fingerprint(it["body"]), []).append(it)
    dupes = {k: v for k, v in groups.items() if len({i["pr"] for i in v}) > 1}

    if args.json:
        print(json.dumps({"repo": repo, "stack": order, "findings": items,
                          "duplicate_groups": [[i["id"] for i in v] for v in dupes.values()]},
                         indent=2))
        return

    if not items:
        print("\nNo outstanding review feedback anywhere in the stack.")
        return

    kinds = {}
    for it in items:
        kinds[it["kind"]] = kinds.get(it["kind"], 0) + 1
    print(f"\n{len(items)} outstanding finding(s) across {len(order)} PRs "
          f"({', '.join(f'{v} {k}' for k, v in sorted(kinds.items()))})\n")
    print(f"{'POSTED':>7} {'OWNS':>7}  {'AUTHOR':<16} {'KIND':<14} WHAT")
    print("-" * 104)
    for it in sorted(items, key=lambda x: (order.index(x["pr"]), x["kind"])):
        owns = f"#{it['owner_pr']}" if it["owner_pr"] else "—"
        what = (f"{it['path']}:{it['line'] or it['original_line']}" if it["kind"] == "thread"
                else claim(it["body"]).replace("\n", " ")[:46])
        flag = "" if it["owner_pr"] == it["pr"] else f"   <- {it['owner_reason']}"
        print(f"{'#' + str(it['pr']):>7} {owns:>7}  {it['author']:<16} {it['kind']:<14} {what}{flag}")

    print("\nBy owning PR — one agent per PR, never one per finding:")
    for pr in order:
        mine = [i for i in items if i["owner_pr"] == pr]
        if mine:
            print(f"  #{pr}: owns {len(mine)} finding(s)")
            for it in mine:
                where = "" if it["pr"] == pr else f"  (raised on #{it['pr']})"
                what = (f"{it['path']}:{it['line']}" if it["kind"] == "thread"
                        else claim(it["body"]).replace("\n", " ")[:60])
                print(f"      - [{it['kind']}] {what} by {it['author']}{where}")

    orphans = [i for i in items if not i["owner_pr"]]
    if orphans:
        print(f"\n{len(orphans)} finding(s) with no single owning layer — judge these yourself:")
        for it in orphans:
            cands = it.get("candidates") or []
            hint = f" candidates {['#' + str(c) for c in cands]}" if cands else ""
            print(f"  #{it['pr']} [{it['kind']}] {it['owner_reason']}{hint}")
            print(f"      {claim(it['body']).replace(chr(10), ' ')[:88]}")

    unresolvable = [i for i in items if not i["resolvable"]]
    if unresolvable:
        print(f"\n{len(unresolvable)} finding(s) live in review bodies or issue comments, which")
        print("GitHub cannot resolve and which have no per-finding thread. Acknowledge them")
        print("with one reply per PR covering each item, via `gh pr comment <pr>` — not one")
        print("reply per finding, which spams the conversation.")

    if dupes:
        print(f"\n{len(dupes)} finding(s) raised on more than one layer. Fix once, at the owning")
        print("layer; reply on the copies pointing at it. Fixing each separately makes")
        print("competing hunks that collide during the cascade:")
        for v in dupes.values():
            prs = sorted({i["pr"] for i in v}, key=order.index)
            print(f"  - {', '.join('#' + str(p) for p in prs)}: "
                  f"{claim(v[0]['body']).splitlines()[0][:76]}")

    print("\nThis is a hypothesis. Blame names the commit that last touched a line, and the")
    print("pickaxe names commits that changed a quoted fragment — neither is proof that the")
    print("layer caused the finding. Confirm against the diff before moving a fix.")


if __name__ == "__main__":
    main()

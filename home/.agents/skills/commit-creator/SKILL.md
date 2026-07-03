---
name: commit-creator
description: "Create git commits from the worktree: inspect changes, group by intention, stage selectively, write Conventional Commit messages (no scopes, imperative, why-focused bodies). Use for any commit request — 'commit this', 'commit and push', 'stage and commit', 'write the commit message', 'split into separate commits', 'create atomic commits', or similar."
context: fork
agent: cheap-runner
---

Atomic commits. Conventional Commits.

**Being invoked IS the instruction.** You run as a fork with no view of the calling conversation. Never ask for a task — run the workflow against the current worktree. Any prompt context is a hint, not a prerequisite. Stop early only if there's nothing to commit.

## Workflow

Two bundled scripts (in this skill's `scripts/` dir — you're given the base
directory at launch) make the mechanical steps deterministic, so spend your
attention on grouping and messages, not on git plumbing.

1. **Inspect.** `bash <skill-dir>/scripts/inspect.sh` — one read-only snapshot:
   branch, status, per-file changes (including untracked files, which `git diff`
   alone hides), diffstat, and the full diffs. Read it to decide the grouping.
2. **Group by intention** → one commit per intention (see Splitting).
3. **Commit each intention.** Write the message to a file (Write tool — subject
   on line 1, blank line, then body), then run:
   `bash <skill-dir>/scripts/commit.sh <message-file> <pathspec>... [--patch <patch-file>]...`
   It stages exactly what you pass (never the whole tree), commits via the file
   so quotes/newlines/`$`/`!` in the message can't be mangled by the shell,
   rejects a subject that isn't a scope-less Conventional Commit, and prints the
   result. Pass every pathspec that belongs to the intention. If inspect shows
   already-staged files that don't belong to this commit, unstage them first
   with `git restore --staged -- <path>`.

### Hunk-level splits (one file, two intentions)

When a single file mixes two intentions, commit them separately by staging only
the relevant hunks — the deterministic, non-interactive alternative to
`git add -p`:

1. Slice the file's hunks out of inspect's FULL DIFF into a `.patch` file (keep
   the `diff --git`/`---`/`+++` header plus the `@@` hunks you want) and pass it
   as `--patch`. `commit.sh` applies it to the index with `git apply --cached`;
   the other hunks stay unstaged for the next commit.
2. If the two changes sit within ~3 lines of each other, `git diff` merges them
   into one hunk. Regenerate with less context to separate them:
   `git diff -U1 -- <file>`, or `git diff -U0 -- <file>` for adjacent lines.
   `commit.sh` detects a zero-context patch and applies it by position.
3. A clean 2-way split often needs just one patch: `--patch` the first
   intention and commit, then the leftover changes are simply
   `commit.sh <msg> <file>` for the second.

## Subject

`<type>: <description>` — no scope. `feat: add x`, not `feat(api): add x`.

- Imperative ("add", not "added")
- Lowercase; acronyms stay caps (API, URL, HTTP)
- No trailing period
- Short — summary, not story

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`

## Body

Why, not what. Diff shows what.

Skip body if subject suffices — most small commits need none. Add only when it helps a future reader: why needed, why this approach, hidden context. Don't pad.

Blank line after subject, then wrapped prose. Bullets OK for distinct reasons.

## Splitting

By intention, not file type. "Same piece of work?" not "same file type?"

Together: impl + its tests + its docs.
Apart: unrelated changes sharing the worktree; incidental fix riding along; distinct reviewable steps of a larger feature.

Unsure → fewer coherent commits.

## Examples

Subject only:
- `fix: prevent crash when config file is missing`
- `docs: clarify install steps for Windows`
- `chore: bump eslint to v9`

With body (why isn't obvious):
```
fix: debounce search input

Endpoint hit on every keystroke, buckled under fast typing.
300ms debounce cuts requests, no noticeable user delay.
```

Split — feature + unrelated typo:
1. `feat: add CSV export to reports page` (tests/docs ride along)
2. `fix: correct typo in onboarding email`

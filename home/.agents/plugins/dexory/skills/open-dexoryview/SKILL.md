---
name: open-dexoryview
description: Generate an authenticated magic-link and open DexoryView in a real browser via agent-browser. Use this whenever you need visual confirmation of DexoryView — checking a design or UI change actually looks right, verifying a fix rendered correctly, poking around a page before describing it, or the user asks to "open dexoryview", "show me the app", "check this in the browser", "log in and look at X". Works against the current local worktree by default, or a review app when a PR number is given. Don't just read the code and assume the UI is correct when the user cares about how it looks — use this skill to actually look.
allowed-tools: Bash, Skill
---

# Open DexoryView

Logs into DexoryView with a one-time magic link and hands the browser off to
`agent-browser` so the app can actually be looked at, not just read as code.

## 1. Pick the target

- **Local worktree (default):** the DexoryView instance running for whichever
  worktree the agent is currently in.
- **Review app:** only when the user is explicitly checking a PR's review app
  — pass `--pr <number>` instead of `--local <port>`.

Don't mix the two — `dv-cli magic-link` requires exactly one of `--local` or `--pr`.

## 2. Get the local port (local target only)

Local worktree port: !`wt port`

`wt port` is a project alias (`.config/wt.toml`) that hashes the current
branch to its assigned dev-server port, so the value above is always the
right one for whatever worktree this agent is running in — no need to ask
the user or guess 3000.

## 3. Make sure the server is actually running

A magic link is useless if nothing's listening on that port yet — check first:

```bash
curl -sf -o /dev/null "http://localhost:<port>/"
```

If that fails, the dev server for this worktree isn't up. Start it in the
background (don't run it in the foreground — it's a long-lived process) and
give it time to boot, since Rails and vite both need to come up:

```bash
wt step dev > /tmp/dexoryview-dev-<port>.log 2>&1 &
sleep 30
```

Then retry the `curl` check before moving on. If it's still not responding,
something's actually broken — check the log rather than pushing ahead to
generate a link nothing will answer.

## 4. Generate the magic link

Run from the repo root:

```bash
"$(git rev-parse --show-toplevel)/bin/dv" magic-link \
  --local <port> \
  --customer dexory \
  --site wallingford \
  --role admin
```

For a review app, swap the target flag:

```bash
"$(git rev-parse --show-toplevel)/bin/dv" magic-link \
  --pr <number> \
  --customer dexory \
  --site wallingford \
  --role admin
```

Defaults — use these unless the user's request implies otherwise:

| Flag | Default | Override when |
|---|---|---|
| `--customer` | `dexory` | user names a different customer |
| `--site` | `wallingford` | user names a different site |
| `--role` | `admin` | user wants to check permissions for another role (`user`, `super_user`, `super_admin`) |

The only real roles are `user`, `super_user`, `admin`, `super_admin`
(`app/models/user.rb`) — ignore `dv-cli`'s own `--help` text and example,
which also list a `site_admin` role; that's stale and the server rejects it.
Also, `admin`/`super_admin` only work for Dexory-internal customers (like
the `dexory` default) — for any other customer (Alloga, Yusen, etc.) the
highest real role is `super_user`, so use that if the user asks for an
"admin" login on a non-Dexory customer.

The command prints the magic link as the **first line** of stdout, followed
by an unrelated Playwright note — take only that first line as the URL. The
link is single-use-ish but gets cached and reused for ~5 minutes for the same
target/customer/site/role, so re-running this for the same page is cheap.

## 5. Open it in the browser

Invoke the `agent-browser` skill and use its CLI to navigate to the magic
link URL, then drive the browser (screenshot, click, inspect) to do whatever
visual check prompted this in the first place.

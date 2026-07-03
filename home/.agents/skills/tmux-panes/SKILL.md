---
name: tmux-panes
description: >-
  Reach for this skill any time a request points at a terminal pane that isn't
  the one you're typing in. You run inside a tmux pane alongside sibling panes —
  shells, REPLs, editors, and agents — that the user addresses as "pane 2",
  "pane 3", "the other pane", "the parent pane", "back to me", or "my agent
  panes", usually without saying the word "tmux". Fire it to: read or summarise
  what another pane shows ("what's pane 3 doing", "its last 20 lines", "did the
  migration finish over there"); type or paste text/a prompt into a pane and
  submit it ("paste this into pane 2", "drop 'continue' into pane 1 and hit
  enter"); reply to the pane that spawned you; or split off a new pane and run a
  command in it. Route every such request through this skill rather than running
  tmux send-keys/capture-pane yourself, which hits the wrong pane and mangles
  multi-line pastes. Not for VS Code/editor splits, background jobs, pasting
  output back into this chat, or Orca/other-tool terminals.
---

# Driving tmux panes

You are almost certainly running inside a tmux pane right now, alongside other
panes the user can point at by number or relationship. This skill makes acting
on them instant and correct: one script, `scripts/paneutil`, resolves references
and performs the operation. Invoke it directly — don't re-derive the tmux
incantations each time.

```
paneutil info                     # the map: every pane, its id, parent, command, title; marks SELF
paneutil send <selector> --file … # paste + submit into a pane
paneutil read <selector> [lines]  # look at what a pane shows
paneutil resolve <selector>       # selector -> pane id (for composing your own commands)
paneutil spawn …                  # split off a child pane with tracked parentage
```

`scripts/paneutil` is on the skill path; call it by its full path if it isn't on
`$PATH` (e.g. `"$CLAUDE_SKILL_DIR"/scripts/paneutil` or the absolute path where
this skill lives). Run `paneutil help` for the full option list.

## The three things people get wrong (and this skill gets right)

Internalise these — they are the reason the skill exists.

1. **"Which pane am I?" is `$TMUX_PANE`, full stop.** It is *not* the pane with
   `active=1`, and *not* what a bare `tmux display-message` prints. Those report
   wherever the **human is currently looking**, which is frequently a *different*
   pane than the one your process runs in (e.g. the user clicks over to watch
   pane 3 while you work in pane 4). If you identify "self" by the active flag,
   "reply to me" and self-send guards target the wrong pane. `paneutil` reads
   `$TMUX_PANE` and nothing else.

2. **"pane 3" means `pane_index` 3 in the current window.** Indices are
   per-window and honour `pane-base-index` (often 1-based). `paneutil resolve 3`
   maps it to the stable pane id (`%88`-style) that every other command should
   use — ids don't shift when panes open or close, indices do.

3. **Pasting into a live app must use bracketed paste, not raw key-streaming.**
   The receiving pane is usually a running TUI — Claude Code, a Python/psql REPL,
   vim. Streaming multi-line text with `send-keys` submits early on the first
   newline and mangles special characters. `paneutil send` loads the text into a
   tmux buffer, pastes it with bracketed-paste framing (so the app treats it as
   pasted content), then sends a single `Enter` after a short delay to submit.

## Common jobs

**Get your bearings.** Before acting on "pane N", glance at the map:

```
paneutil info
```

It prints every pane with its `win.idx`, stable id, recorded parent, running
command, and title, marks which one is SELF, and stars the current window. This
replaces the usual flurry of `list-panes` / `display-message` probing.

**Send a message or prompt to another pane.** For anything multi-line (a review,
a code block, a prompt for another agent), write it to a file and send the file —
quoting survives untouched:

```
paneutil send 3 --file /path/to/message.txt      # paste into pane 3 and submit
paneutil send 3 --text "run the tests" --no-enter # stage text without submitting
paneutil read 3 20                                # confirm it landed / see the reply
```

`send` **refuses to target SELF by default** — sending your own pane your own
prompt is almost always a mistake born of the active-pane confusion above. Pass
`--allow-self` only if you genuinely mean it.

**Reply to whoever spawned you.** If this pane was split from another (and parent
tracking is on — see below), you don't need the index:

```
paneutil send parent --file /path/to/reply.txt
```

**Spawn a worker pane and keep the lineage.** `spawn` splits a pane, stamps the
new pane with its parent, and prints the new id so you can drive it:

```
new=$(paneutil spawn --dir v --command "claude" --title "worker")
paneutil send "$new" --file /path/to/task.txt
```

## Parent/child lineage

tmux has **no native concept of a parent pane**, so this skill records it in a
per-pane user option, `@dv_parent_pane`. Two ways it gets set:

- **`paneutil spawn`** always records it for panes it creates. Reliable, no setup.
- **`paneutil install-hook`** adds a global `after-split-window` hook to
  `~/.tmux.conf` so that *every* future split — including manual `Ctrl-b %` /
  `"` splits the user makes — auto-records its parent. This is what lets "send it
  back to the parent pane" work for panes you didn't create yourself.

Panes created *before* tracking was enabled (or root panes with no parent) have
no recorded parent; `paneutil send parent` will say so plainly rather than guess.
If the user wants relationship-based addressing to work everywhere, offer to run
`paneutil install-hook` once. `paneutil uninstall-hook` reverses it.

Lineage chains: `paneutil resolve parent-of:parent` walks up two levels, etc.

## When NOT to reach for this

- The user means an **Orca-managed** terminal/worktree, iTerm/Warp split, or a
  desktop app pane — those aren't tmux. Check `echo "$TMUX"`: empty means you're
  not in tmux and `paneutil` will tell you so. Use the appropriate tool instead.
- Structured multi-agent coordination with inboxes, task DAGs, and reply
  tracking is a different problem — that's what an orchestration layer is for.
  `paneutil` is for direct, immediate "put this there / read that / reply here"
  pane manipulation, not durable message routing.

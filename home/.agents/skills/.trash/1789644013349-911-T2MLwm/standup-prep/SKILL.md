---
name: standup-prep
description: "Send a direct Slack message to myself summarizing everything worth mentioning at my daily stand-up for a specific project: Basecamp board movement/comments, related GitHub PR reviews, Slack activity, emails, and meeting/transcript follow-ups, since the last stand-up. Use only when I ask to run or set up my stand-up prep, or invoke /standup-prep by name."
---

## Variables

Edit these when the project or schedule changes — nothing else in this skill should need to change.

```
PROJECT          = "Adapt"   # passed to briefing-sources as PROJECT_SCOPE
STANDUP_TIME     = "14:30"         # time of the actual stand-up meeting
ROUTINE_RUN_TIME = "14:00"         # time this routine is scheduled to run, daily
SLACK_TARGET     = "me"            # send as a Slack DM to myself
```

## Setup

When I ask to set this up as a recurring task, schedule it for `ROUTINE_RUN_TIME` on weekdays. Infer the language to write in from how I phrase the setup request, and write that into the scheduled task's prompt so unattended runs don't have to guess.

## Gather

Use the `briefing-sources` skill for all data gathering — it owns the window calculation, and the Basecamp/GitHub/Slack/email/calendar/transcript search rules and freshness check. Call it with:

```
WINDOW_START/END = briefing-sources' default weekday-aware helper, given ROUTINE_RUN_TIME
PROJECT_SCOPE    = PROJECT   (single-project scope — not "all")
SOURCES          = basecamp, github, slack, email, calendar, transcripts
```

Everything returned has already passed the freshness check — nothing stale or already-handled should reach the Sort step below. Let this take a minute if run interactively; on an unattended scheduled run, no prompts, just gather and send.

## Sort

**Board — which cards get listed.** A card appears in its column's list if, within the window, it: moved into that column, received a comment/activity, OR is currently sitting in an active-work column (In Progress, In QA, Ready for QA) and assigned to me — even with zero activity, since stand-up needs the full state of what's in flight, not just what changed. Cards untouched in Planned, or old Done items, are omitted entirely rather than padding the list.

**Board — column order.** List columns right-to-left, matching how the stand-up actually walks the board:

1. Done
2. QA Done
3. In QA
4. Ready for QA
5. In Progress
6. Planned

Within each column, On Hold cards are listed inline with the others (not split into a sub-section), flagged with ⏸.

**Per-card status sentence.** Every listed card gets exactly one sentence of status:
- Changed: "moved to {column} — {who}, {when}" or "{who} commented: {short paraphrase}"
- Unchanged: "no change since last stand-up — still {current status/column}, {brief context if any}"

**Urgent callout.** A separate item earns a place in the top-level callout (shown once, near the top, before the board) if it meets either:
- A direct @-mention or question aimed at me, in Basecamp/Slack/email, still unanswered, OR
- Anything explicitly tagged or worded as "blocker" / "urgent" in Basecamp or Slack.

These also stay nested in their normal place (under their card, or in Slack/email) — the callout is a pointer, not a replacement.

**Emails / meetings.** Only items that are new, unresolved, or need a decision from me. A thread that resolved itself, or a meeting that was purely informational and already covered elsewhere, is dropped.

**PR reviews.** A PR returned by `briefing-sources` that's already linked under a Basecamp card doesn't get repeated. Only PRs that aren't tied to any card on the board get their own line, so review requests never fall through the cracks just because they lack a card.

Nothing found anywhere → the whole message becomes one line: "Nothing new on {PROJECT} since {last stand-up day}."

## Write

Compose as a single Slack message (not a canvas, not an artifact) and send it as a DM to `SLACK_TARGET` via Slack. Use Slack's own markdown (bold with `*asterisks*`, links as `<url|text>`), not standard markdown — Slack renders `**bold**` and `[text](url)` literally, so get this right.

Template (sections with nothing in them are dropped entirely — no empty headers, no "nothing here" placeholders except the single all-quiet line above):

```
📋 *{PROJECT} Stand-up Prep* — {day, date} (since {last stand-up day/time})

⚠️ *Needs attention*
• {one line per urgent item, with link}

🟢 *Done*
• <card-url|{Card title}>{ — PR <pr-url|#123>} — {status sentence}
   ↳ {nested comment paraphrase, if any}

✅ *QA Done*
• ...same shape...

🔍 *In QA*
• ...

🧪 *Ready for QA*
• ...

🚧 *In Progress*
• ...(⏸ prefix if On Hold)...

📝 *Planned*
• ...

🔗 *PR reviews (not tied to a card)*
• <pr-url|{repo}#{number}> — {one line, e.g. "review requested by X, {when}"}

📨 *Notable emails*
• {who/subject} — {one line}, <link|view>

📅 *Meeting follow-ups*
• {one line}
```

Keep every bullet to one line where possible; the nested comment line under a card is the one allowed exception, and itself should be one short paraphrased sentence.

## Ground rules

- Never quote Basecamp comments, Slack messages, or emails verbatim beyond a short phrase — paraphrase.
- Every card and PR reference is a live link, never a bare title with no link when a URL exists.
- This skill only ever gathers and sends the one Slack DM to myself — it never posts to any other channel, comments on any card, or replies to any email/message on my behalf.
- If Basecamp is unreachable (CLI error, auth failure) for a run, don't fail silently — say so plainly in the message ("Basecamp board activity couldn't be pulled this run — {short reason}") rather than omitting the whole board section as if nothing happened there.
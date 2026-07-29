---
name: basecamp-handoff
description: Hand a completed piece of work back to the team on Basecamp. Posts a friendly, non-technical comment on the card describing what changed, how to verify it, and includes the PR and review-app links. Then moves the card to the ready-for-QA column. Generates acceptance criteria from the actual changes (PR diff + card context). Use this when the user has finished work, has an open PR, and wants to update Basecamp — triggers include "hand off to QA", "ready for QA", "update the basecamp card with the PR", "finish on basecamp", "let QA know it's ready", "this is done, update basecamp". Composes with the pr-creator skill if no PR exists yet.
allowed-tools: Bash, AskUserQuestion, Skill
---

# Dexory Basecamp Handoff

Hand a completed piece of work to the team for QA: post a clear, non-technical comment on the Basecamp card that explains what changed and how to verify it, include the PR and review-app links, then move the card to the ready-for-QA column.

The comment style mirrors `basecamp-comment`: written for product managers and designers, no developer jargon, plain English. The acceptance criteria are derived from the actual code changes so QA has a concrete checklist.

## Steps

### 1. Resolve the card

This skill runs in a forked context and cannot see the parent agent's conversation. The parent agent almost always knows which card this work belongs to — it was named when the card was picked up, or referenced in the PR creation flow, or otherwise established in the session. The parent must pass the card URL explicitly in the invocation message (see "Notes for callers" at the bottom). Treat any URL passed in the invocation as authoritative.

Find the card URL by trying these in order, stopping at the first one that works:

1. **Invocation message or recent user message.** If the parent agent passed a card URL in the invocation, or the user pasted one in the recent conversation, use that.
2. **PR description.** Run `gh pr view --json body,title 2>/dev/null` and search the body and title for a `https://3.basecamp.com/.../card_tables/cards/<id>` URL.
3. **Ask.**

   ```
   AskUserQuestion: "Which Basecamp card should I update? Paste the URL."
   ```

Parse the URL:

```bash
basecamp url parse "<url>" --json
```

Use `project_id`, `recording_id` (card ID), and `card_table`.

### 2. Get the PR and the review app link

Check whether the current branch has an open PR:

```bash
gh pr view --json number,url,title,body,baseRefName 2>/dev/null
```

**No PR open.** Ask the user how to proceed:

```
AskUserQuestion: "There's no PR open on this branch yet. What now?"
  - "Create one with the pr-creator skill"
  - "I'll open it myself, pause this"
  - "Proceed without a PR or review-app link"
```

If the user picks "Create one", invoke the `pr-creator` skill. The `pr-creator` skill runs in a forked context and cannot see this conversation, so pass the resolved Basecamp card URL (and any Jira ticket key the user has mentioned) explicitly in the invocation message — for example: "Create a PR. Basecamp: https://3.basecamp.com/.../cards/55510". Then re-run `gh pr view` to pick up the newly opened PR. If the user picks "pause", stop the skill cleanly. If they pick "proceed without", skip the review-app link in step 5.

**PR exists.** Construct the review-app link:

```
https://{number}.review.dexoryview.com/
```

### 3. Generate acceptance criteria from the changes

The point of these criteria is to give QA a concrete, user-facing checklist of what to verify. Derive them from the actual changes, not from generic templates.

Sources to look at:
- `gh pr view --json body,title` — the PR title and description, which usually summarise the change in plain English already.
- `git diff <baseRefName>...HEAD` — the actual code changes. Translate user-facing changes into things a non-technical person can check (e.g. "the filter no longer shows archived items by default" rather than "removed `where(archived: false)`").
- The card body and existing comments — for the original problem statement and any criteria the team has already discussed.

Write 2–5 short, plain-English bullets, each describing something a QA person can verify on the review app by clicking around. Skip internal refactors that aren't user-visible.

### 4. Read the card for context

```bash
basecamp cards show "<url>" --json
basecamp comments list "<url>" --in <project_id> --json
```

Read the title, body, and existing comments. Use this to:

- Match the tone and vocabulary already used in the thread
- Avoid re-explaining context that's already established
- Cover only what's new, not the full history

### 5. Draft the comment

**Before writing a word, invoke the `tone-of-voice` skill and follow it.** The comment goes out under Mark's name, so his register governs the prose: first person, casual but properly written, no ceremony or performed ownership, no em dashes, British spelling, no emoji or exclamation marks. Read it before drafting, not after.

Audience is product managers and designers, so plain English and no developer jargon on top of that.

**Structure:**

- Opening: a short, natural sentence saying it's done and what to look at, written for people who already read the card. Do **not** restate the original problem; the title and body of the card already say it, and parroting it back ("There was an issue where X was doing Y, this is now fixed") reads like a chatbot summary, not a teammate's update. Skip straight to what's new: what changed, what to check, anything QA should know that isn't already on the card. Plain sentences, no list. Only fall back to a bullet list here if there are genuinely multiple distinct issues being addressed in the same handoff and a list makes them clearer than a paragraph would. A single change should always read as a sentence, never a one-item bullet list.
- A **To verify:** section with the acceptance criteria from step 3, as a bullet list.
- PR link and review-app link at the end, formatted identically so they read as a matched pair. Use a bold label followed by the link, as a two-item bullet list:
  ```markdown
  - **GitHub PR:** https://github.com/dexory/.../pull/1234
  - **Review app:** https://1234.review.dexoryview.com/
  ```
  A list keeps the two on separate lines reliably; two plain lines separated by a single newline would collapse into one paragraph when the Markdown is converted. Same label style, same order every time (PR first, review app second). Do not vary the phrasing — consistency makes the links easier to scan and matches the rest of the team's style.

**Audience rules (on top of `tone-of-voice`):**

- No technical terms: avoid "PR", "branch", "merge", "deploy", "refactor", "API", "regression", "null", "undefined", etc. Translate them: "PR" → "the change" or omit, "deploy" → "live", "regression" → "issue".
- Plain verbs: "fixed", "updated", "added", "changed", "now shows".
- Short: a few sentences plus the verification list.
- **Vary the opening phrase.** Don't reach for the same stock phrase every time, especially not "ready for a look", which has been overused and now reads as a tell. Pick whatever fits the change: "ready to review", "this is fixed", "this is done", "sorted", "live on the review app now", "give this a go when you get a chance", or just a plain statement of what changed. Re-read the comment before posting and ask whether the same wording has shown up on the previous handoff. If yes, rewrite.
- No bolded mini-headers in the prose body. Bold is for the **To verify:** label, the link labels, and genuine emphasis on a single word, not for decorating every paragraph.

**Format: write the comment as Markdown.** The Basecamp CLI converts Markdown to rich text when it posts, so write plain Markdown and let it handle the rendering. Never hand-write HTML.

- Blank line between blocks (paragraphs, lists, the link pair) so the comment doesn't read as a wall of text.
- `**bold**` for emphasis where it helps.
- `-` bullets for lists.
- `[text](url)` for links, or a bare URL.
- No headers unless content genuinely calls for it.

**Example — single issue (don't restate the problem; the card title already says it):**

Card title: "Archived items showing in default list view"

```markdown
Fixed. Also gave the empty state a proper message for when there's nothing in the list.

**To verify:**

- Open the items list and confirm only active items appear.
- Apply the filter and confirm archived items stay hidden.
- Empty the list and confirm the new empty-state message shows.

- **GitHub PR:** https://github.com/dexory/.../pull/1234
- **Review app:** https://1234.review.dexoryview.com/
```

Note how the opening doesn't repeat "the items list was showing archived items by default". The card title already says that. The comment just says it's done and flags the one extra thing (the empty state) that wasn't on the original card.

**Anti-example — what not to write:**

```markdown
There was an issue where archived items were showing in the default list view, making the page feel cluttered as soon as it loaded. This has now been fixed.
```

This is what the rule above is warning against: the first sentence is just the card title rephrased back at the reader. Cut it.

**Example — multiple distinct issues (list is justified, and the issues weren't all on the original card):**

```markdown
A few things on the items page, all sorted now:

- Archived items were showing up in the default view.
- The empty state was blank instead of explaining what to do next.
- Sorting by date was reversed.

**To verify:**

- Open the items list and confirm only active items appear.
- Empty the list and confirm the new empty-state message shows.
- Sort by date and confirm newest items appear first.

- **GitHub PR:** https://github.com/dexory/.../pull/1234
- **Review app:** https://1234.review.dexoryview.com/
```

A list at the top is fine here because the bundle covers things beyond the original card's scope, so listing them is genuinely informative rather than parroting.

If the user pasted screenshots in the conversation, note their paths — they'll be attached via `--attach` in step 7.

### 6. List columns and pick the ready-for-QA target

```bash
basecamp cards columns --in <project_id> --card-table <card_table> --json
```

Fuzzy-match the QA column by keyword (case-insensitive substring): `qa`, `review`, `ready`, `test`, `verify`. Pick the best match. If multiple match (e.g. "Ready for QA" and "Code Review"), surface the ambiguity in the plan.

If no column matches, ask the user to pick from the full list during confirmation.

### 7. Show the plan and confirm once

**Do not use `AskUserQuestion` for this step.** The user has to be able to see the full drafted comment to review it, and `AskUserQuestion` hides long content behind its UI — past handoffs have been approved blind because the comment wasn't visible.

Print the plan as plain assistant text output. Include:

- **The drafted comment, in full, as a fenced ```markdown code block** so the user can read the exact content that will be posted. Do not summarise, truncate, or paraphrase it — print it verbatim.
- Target column move: current → new
- Screenshots to attach, if any (list the file paths)

Then, in prose underneath, ask the user to reply with one of: "post" (post and move), "edit" (describe what to change), "column" (pick a different target column), or "cancel". Wait for a free-text reply — this is the one place in the skill where a prose question is correct, because the user needs the comment text visible while they decide.

All other prompts in this skill (card URL fallback in step 1, the no-PR branch in step 2, picking a column if no fuzzy match in step 6) still go through `AskUserQuestion` as normal.

### 8. Execute

Two separate commands. Run them in this order. Use the exact flag names and structure shown — getting these wrong has caused real failures (column names ending up in card bodies, screenshots ending up in Docs & Files instead of on the comment).

#### 8a. Post the comment

```bash
basecamp comment <card_id_or_url> "<markdown_content>" --in <project_id>
```

**With screenshots**, attach them as part of the same `basecamp comment` call by passing `--attach <path>` once per file. There is no separate upload step.

```bash
basecamp comment 55510 "Ready for QA…" --in 12345678 \
  --attach /Users/me/Desktop/screenshot1.png \
  --attach /Users/me/Desktop/screenshot2.png
```

Rules:
- Pass the comment Markdown as a single quoted string in the `<content>` argument. The CLI converts it to rich text on the way in, so never hand-write HTML. Watch the shell quoting: single quotes around content containing double quotes, or escape as needed.
- Each screenshot is a separate `--attach <path>` flag — the flag is repeatable. Paths must be local files Claude can read; absolute paths are safest.
- The standalone `basecamp attach` and `basecamp upload` commands are for adding documents to a project's Docs & Files area as separate items — they are **not** for adding screenshots to a comment. Always use the `--attach` flag on `basecamp comment`.
- Only attach screenshots the user actually pasted in the conversation. Do not invent paths or attach files the user didn't provide.

#### 8b. Move the card to the QA column

```bash
basecamp cards move <card_id_or_url> --to "<target_column_name_or_id>" --in <project_id>
```

Concrete example:

```bash
basecamp cards move 55510 --to "Ready for QA" --in 12345678
```

Critical rules — getting any of these wrong is what caused past failures:
- The column goes in **`--to`**. Never in the card title, body, or comment content. There is no `cards move` flag that takes the column as positional content.
- The first positional argument is the **card** ID or URL — not the column. Order matters.
- `--to` accepts either the column's ID (`col-qa`) from `basecamp cards columns --json` or its display name (`"Ready for QA"`). Quote the name if it contains spaces.
- This is `basecamp cards move`, not `basecamp cards update`. **Do not** try to "move" by calling `basecamp cards update --body "Ready for QA"` — that overwrites the card body with the literal string "Ready for QA". `update` cannot change a card's column at all.
- `--in <project_id>` is required so the CLI knows which project's card-table to operate on.

Verify the move succeeded by checking the JSON response (`"moved_to": "Ready for QA"` or similar) before reporting completion to the user. If the response shows the card is still in the old column, re-run with the column **ID** (e.g. `--to col-qa`) instead of the display name and try again.

### 9. Confirm

Print:

- Card URL
- New column
- A note that the comment was posted (and screenshots attached, if any)

## Notes

- **Most questions go through the `AskUserQuestion` tool**, with one exception: the step 7 plan/confirmation, where the drafted comment must be printed inline as assistant text so the user can actually read it before approving. Everywhere else (card URL fallback, no-PR branch, column disambiguation, anything else that comes up), use `AskUserQuestion` with explicit options where the answer is constrained, or a single open-ended question where it isn't.
- **Don't reuse `basecamp-comment` directly via the Skill tool.** The user is planning to modify that skill; copy its style guidance here rather than depending on it. The `tone-of-voice` skill is the one exception: always invoke it, never inline a copy of it.
- **AC is generated, not extracted.** Even if the card body has a list of original AC, derive the verification checklist from the actual changes — what's there to verify now might differ from what was originally scoped.
- **No PR + user picks "proceed without"** → still post the comment and move the card, just omit the PR/review-app links.
- **Always derive `--card-table` from the URL.** Don't prompt.

## Notes for callers

This skill runs in a forked context and cannot see the parent conversation. The parent agent (or another skill) **must pass the Basecamp card URL explicitly in the invocation message** — do not rely on the skill to figure it out from PR body alone, since that's a fallback and can pick up the wrong card or miss it entirely.

Sources the parent should check, in order, before invoking:

1. **basecamp-pickup handoff.** If the card was picked up earlier in this session, the URL appeared verbatim in the pickup handoff block (`**URL:**` line). Use that.
2. **Recent user messages.** Any `https://3.basecamp.com/.../card_tables/cards/<id>` URL pasted by the user.
3. **PR body.** A card URL the user added when the PR was opened.
4. **Ask the user.** Only if all of the above are silent.

Pass the URL into the skill invocation. Example:

```
Hand this off on Basecamp: https://3.basecamp.com/9999999/buckets/12345678/card_tables/cards/55510
```

If the parent agent has additional context the skill needs (screenshots the user pasted, a specific QA column the user asked for, custom acceptance criteria the user already wrote), include those in the invocation too. Without the URL, the skill has to fall back to PR-body sniffing or asking — slower, more error-prone, and can land the comment on the wrong card.

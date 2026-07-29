---
name: basecamp-comment
description: Post a comment on a Basecamp card to say a task or fix has been completed. Uses the Basecamp CLI to add the comment and upload any screenshots. Use when finishing work and wanting to update a Basecamp card, when asked to "comment on basecamp", "update the basecamp card", "post to basecamp", or "let the team know it's done".
allowed-tools: Bash, AskUserQuestion, Skill
context: fork
model: sonnet
disable-model-invocation: true
---

# Dexory Basecamp Comment

Post a clear, friendly update on a Basecamp card to let the team know work is complete. Written for a non-technical audience — no code, no jargon, just plain English about what changed and how to try it. Screenshots can be uploaded alongside the comment.

## Steps

### 1. Get the Basecamp card URL

If the user has not provided a Basecamp card URL, ask for it:

```
AskUserQuestion: "What's the Basecamp card URL you'd like to comment on?"
```

Once you have the URL, parse it to extract the project and recording IDs:

```bash
basecamp url parse "<url>" --json
```

Use the returned `project_id` and `recording_id` in the comment step.

### 2. Get the review app link

Check whether the current branch has an open PR:

```bash
gh pr view --json number,url 2>/dev/null
```

- If a PR exists, construct the review app link: `https://{number}.review.dexoryview.com/`
- If no PR exists, ask the user:

```
AskUserQuestion: "Is there a review app link for this change? (e.g. https://1234.review.dexoryview.com/) — leave blank if there isn't one."
```

If the user leaves it blank or there is no review app available, omit it from the comment.

### 3. Read the card

Fetch the card to understand the existing conversation before drafting your comment. Use the original card URL the user provided:

```bash
basecamp show "<card_url>" --json
```

Read the card title, description, and any existing comments. Use this to:

- Understand what the audience already knows — don't re-explain context that's already been established
- Match the tone and vocabulary used in the thread
- Only cover what's new since the last update, not the full history of the task

### 4. Check for screenshots

If the user has pasted any screenshots into the conversation, note their file paths — they will be attached directly to the comment using `--attach` flags (see step 7). Do not upload them separately to Basecamp Docs.

You do not need to ask for screenshots. Only attach them if the user has already provided them in the conversation.

### 5. Draft the comment

**Before writing a word, invoke the `tone-of-voice` skill and follow it.** The comment goes out under Mark's name, so his register governs the prose: first person, casual but properly written, no ceremony, no em dashes, British spelling, no emoji or exclamation marks. Read it before drafting, not after.

On top of that, this comment has a specific audience: product managers and designers. Describe everything from a user's perspective, not a developer's.

**What to cover (only include what's relevant):**

- **What was done** — describe the changes made. Use a bullet list when there are multiple distinct changes to highlight individually — one bullet per item, describing what the user now sees or can do, not what code changed. If there is only one change, or you are explaining something rather than listing items, use a paragraph instead. Don't use bullets just to add structure — use them only when a list genuinely helps.
- **How to check it** — if useful, a plain-English step or two explaining how they can verify the changes on the review app. Keep it simple, like you're explaining to a friend.
- **Anything to be aware of** — only if there are caveats, limitations, or follow-up work. Don't add this section if there's nothing notable.

**Audience rules (on top of `tone-of-voice`):**
- No technical terms: avoid words like "refactor", "PR", "merge", "deploy", "commit", "branch", "API", "bug", "regression", "null", "undefined", etc.
- Use plain verbs: "fixed", "updated", "added", "changed", "removed", "now shows", "now works"
- Keep it short. A few sentences is usually enough.

**Format: write the comment as Markdown.** The Basecamp CLI converts Markdown to rich text when it posts, so write plain Markdown and let it handle the rendering. Never hand-write HTML.

- `**bold**` for emphasis where it helps
- `-` bullets for the list of changes
- `[text](url)` for links, or a bare URL
- Blank line between blocks
- No headers unless the content genuinely calls for it

**Include the review app link** (if available) at the end of the comment. Vary the phrasing naturally — don't always use the same phrase. Some options: just the bare link, "Review app:", "Try it out:", "You can check it here:", or a short sentence like "The review app is up at [link] if you want to take a look." Choose whichever feels most natural given the comment's tone.

**Example comment (as Markdown):**

```markdown
This has now been fixed:

- The filter no longer shows archived items. Only active items appear by default.
- The empty state now shows a helpful message when there are no active items to display.

Head to the items list and apply the filter. You should only see active items now.

https://1234.review.dexoryview.com/
```

### 6. Confirm before posting

Show the drafted comment to the user and ask if they're happy with it or want any changes before it goes on the card.

### 7. Post the comment

Once confirmed, post it using the Basecamp CLI. Always use `--attach` to include screenshots directly on the comment — never use `basecamp upload` or `basecamp attach` as a separate step, as that would add them to Docs & Files instead.

```bash
# No screenshots
basecamp comment <recording_id> "<comment markdown>" --in <project_id>

# With screenshots
basecamp comment <recording_id> "<comment markdown>" --in <project_id> --attach path/to/screenshot1.png --attach path/to/screenshot2.png
```

### 8. Confirm completion

Let the user know the comment has been posted (and any screenshots uploaded), and share the card URL.

---
name: basecamp-pickup
description: Pick up a Basecamp card to start work on it. Reads the card body and all comments, downloads any attachments locally so they can be inspected, moves the card to the in-development column, and assigns it to the current user. Hands a structured summary back to the main agent so the next step can be planning the implementation. Use this whenever the user pastes a Basecamp card URL with intent to start work, or says "pick up this card", "start work on this Basecamp card", "I'm starting on this", "let's pick this one up", or anything similar. Also fire if the user mentions a 3.basecamp.com card URL alongside any verb that implies starting work.
allowed-tools: Bash, AskUserQuestion
context: fork
model: sonnet
---

# Dexory Basecamp Pickup

Pick up a Basecamp card so the user can start work on it: read the card and its discussion, pull down any attachments, move the card into the in-development column, and assign it to the user. End with a structured handoff so the main agent has everything needed to plan the implementation.

The skill performs all Basecamp side-effects (move + assign) in a single batch after one user confirmation. If the card is already in the target column, the move is skipped silently.

## Steps

### 1. Get the card URL

If the user already provided a Basecamp card URL, use it. Otherwise:

```
AskUserQuestion: "Which Basecamp card are you picking up? Paste the URL."
```

Parse the URL to extract IDs:

```bash
basecamp url parse "<url>" --json
```

Use the returned `project_id`, `recording_id` (the card ID), and `card_table` if present. Always derive the card table from the URL — do not prompt for it.

### 2. Read the card

Fetch the card body and full comment history:

```bash
basecamp cards show "<url>" --json
basecamp comments list "<url>" --in <project_id> --json
```

Parse:
- Title
- Body (markdown)
- Comments in chronological order (author, timestamp, content)
- Attachment references (uploads embedded in body or comments)
- Current column

The card's body and comments often contain the full context of the issue or feature. Read them carefully — this is the primary input to the action plan.

### 3. Download attachments

For every attachment referenced on the card or in comments, download it to `/tmp/basecamp-pickup/<card-id>/<filename>` using the bundled helper script:

```bash
mkdir -p /tmp/basecamp-pickup/<card-id>
scripts/fetch-attachment.sh "<attachment-url>" "/tmp/basecamp-pickup/<card-id>/<filename>"
```

The script handles the OAuth dance and host-rewrite that `basecamp files download` doesn't cover for inline attachments embedded in card bodies and comments (those URLs use `preview.3.basecamp.com` / `storage.3.basecamp.com`, which only authenticate against the API host). The script lives at `<skill-dir>/scripts/fetch-attachment.sh` — invoke it relative to the skill directory or via its absolute path.

Download all file types — images, docs, zips, anything — **except video files** (`.mov`, `.mp4`, `.webm`, `.avi`, `.mkv`, `.m4v`). The agent cannot read video content, so downloading wastes time and disk. Note skipped video attachments in the handoff (filename + URL) so the user can open them manually if needed.

For everything else, the main agent may need them for context, and the user might want to inspect them. Note the local paths so they can be included in the handoff.

If `basecamp cards show --json` does not surface attachment URLs directly, fall back to `basecamp show <url> --md` and look for embedded upload links, or fetch each comment via `basecamp comments show <id>` to find them. If no attachments exist, skip this step.

### 4. List columns and pick the target

Get the list of columns on this card table:

```bash
basecamp cards columns --in <project_id> --card-table <card_table> --json
```

Match the in-development target by fuzzy keyword on column name (case-insensitive substring): `dev`, `progress`, `wip`, `doing`, `building`. Pick the best match. If multiple columns match (e.g. both "In Development" and "Dev Review"), include the ambiguity in the plan so the user can correct it during confirmation.

If no column matches at all, surface this in the plan and ask the user to pick from the full list during confirmation.

### 5. Build the plan and confirm once

Show the user a single plan summarising every side-effect, and ask for one confirmation before executing anything. Include:

- **Card:** title and URL
- **Current column → target column** (or "already in target — will skip move")
- **Assignee:** me
- **Attachments downloaded:** count and paths under `/tmp/basecamp-pickup/<card-id>/`

Use `AskUserQuestion` with options like "Yes, do it" / "No, cancel" / "Change target column". If the user picks "change target column", show the full column list and let them pick.

If the card is already in the target column AND already assigned to the user, say so and skip straight to the handoff (step 7).

### 6. Execute

Run the side-effects in order. Use the exact flag structure shown — the move command is easy to get wrong (column name in body instead of `--to`).

```bash
# Move (only if not already in target column).
# The card ID/URL is the first positional arg; the column goes in --to;
# --in is the project ID. Quote the column name if it has spaces.
basecamp cards move <card_id_or_url> --to "<column_name_or_id>" --in <project_id>

# Assign to me — try `me` first.
basecamp cards update <card_id_or_url> --assignee me --in <project_id>
```

Concrete example:

```bash
basecamp cards move 55501 --to "In Development" --in 12345678
basecamp cards update 55501 --assignee me --in 12345678
```

`basecamp cards update` cannot change a column — it only edits title/body/assignee/due. Never try to "move" by passing the column name to `--body` or as a positional argument; always use `basecamp cards move` with `--to`.

If `--assignee me` is rejected (some Basecamp endpoints don't accept the literal), ask the user:

```
AskUserQuestion: "How should I identify you for assignment? Provide an email, person ID, or full name."
```

Pass that value to `--assignee` and retry. Do not assume an email address — always ask.

### 7. Hand off to the main agent

End the skill by printing a structured summary block. This is the primary handoff — the main agent reads this and uses it to plan the implementation. Use this exact template:

```
## Card: <title>

**URL:** <card_url>
**Column:** <old_column> → <new_column>
**Assignee:** <who>

### Body

<card body in markdown>

### Comments (chronological)

**<author>** — <timestamp>
<comment body>

**<author>** — <timestamp>
<comment body>

### Attachments

- /tmp/basecamp-pickup/<card-id>/file1.png
- /tmp/basecamp-pickup/<card-id>/file2.pdf

### Acceptance criteria

<extracted from card body if present, otherwise: "Not explicitly listed in card.">
```

Look for an "Acceptance criteria", "AC", "Definition of done", or similarly-headed section in the card body or first comment. If found, include it verbatim. If not, say so — don't invent.

**The full card URL must appear verbatim in the handoff** (in the `**URL:**` field above) so the main agent can reference the card later for follow-up work — opening a PR linked to it, posting a handoff comment, replying to a discussion, etc. Do not shorten, paraphrase, or omit it. If the skill ran without surfacing the URL (e.g. the card was identified by ID alone), reconstruct it from the parsed `project_id`, `card_table`, and `recording_id` and include it.

After the structured summary block, append the following verbatim instruction block so the main agent knows not to charge ahead:

```
---

**Instructions for the main agent:** Do not start planning or implementing yet. The card has been picked up and the context above is the full handoff. Confirm with the user that:

1. The details captured above look complete and correct.
2. Any attachments or comments that matter have been understood.

Then ask the user what they want to do next (e.g. draft a plan, explore the code, start a prototype, ask clarifying questions on the card). Wait for their direction before taking action.
```

After printing the summary and this instruction block, do not start planning or implementing yourself. Stop and let the main agent take over. Your job is done once the card is set up and the context is laid out.

## Notes

- **Any question for the user must go through the `AskUserQuestion` tool.** Never ask in prose and wait for a free-text chat reply — every prompt for input (card URL, target column, assignee identifier, confirmation, anything else that comes up) goes through `AskUserQuestion` with explicit options where the answer is constrained, or a single open-ended question where it isn't.
- **Always derive card-table from the URL.** Do not run `basecamp cards columns` without `--card-table` — projects may have multiple tables and the command will error.
- **Don't post a "starting work" comment.** The move + assignee are sufficient signal; an extra comment is noise.
- **Don't create a git branch.** Branching is the user's call after pickup.
- **Don't write a plan file or seed tasks.** The structured summary is the entire handoff.
- The `disable-model-invocation: false` setting allows the model to invoke this skill on natural-language triggers as well as the `/basecamp-pickup` slash command.

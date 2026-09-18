#!/usr/bin/env python3
"""Pin the text-handling rules. Run: python3 test_collect_stack_reviews.py

These cases are taken from real review comments. They exist because each one was got
wrong at least once: the fingerprint keyed on a reviewer's boilerplate preamble and
called five separate findings one duplicate, and the display showed the preamble rather
than the finding.
"""
import sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).parent))
from collect_stack_reviews import (claim, fingerprint, split_findings, AUTOGEN,
                                   strip_noise, is_answered, last_author_comment_at, is_scaffold)

PREAMBLE = ("**Test-reliability to-do** (from re-running the "
            "[#6256](https://github.com/botsandus/DexoryView/pull/6256) test-reliability "
            "reviewer locally; advisory, nothing blocks. Only the findings that hold up "
            "against source; `@no_browser` / feature-size / `Job conformance check` ones "
            "are convention and I am softening those rules.)")
OPEN_COUNT = (PREAMBLE + "\n\n`features/step_definitions/chatbot_scan_figure_parity_steps.rb` "
              "`tasks_dashboard_open_count`: reads the badge the moment the node exists.")
ROW_COUNT = (PREAMBLE + "\n\n`features/step_definitions/chatbot_scan_figure_parity_steps.rb` "
             "`tasks_dashboard_row_count`: hand-built tasks URL idles the full timeout.")
CODERABBIT = ("_🩺 Stability & Availability_ | _🟠 Major_ | _⚡ Quick win_\n\n"
              "This step mutates `@site` without reloading, so assertions read stale data.")
OWN_REVIEWER = ("<sub>Test reliability</sub>\n\n"
                "This step mutates @site without reloading, so assertions read stale data.")
NUMBERED = (PREAMBLE + "\n\n1. `spec/factories/deployment.rb` `:with_locations`: started_at "
            "drifts.\n\n2. `spec/models/site_spec.rb` `#scan_summary_snapshot`: the window "
            "straddles midnight.")

fails = []


def check(name, cond):
    print(f"{'ok  ' if cond else 'FAIL'} {name}")
    if not cond:
        fails.append(name)


# Two findings sharing a verbatim preamble are two findings, not one.
check("distinct findings with identical preamble differ",
      fingerprint(OPEN_COUNT) != fingerprint(ROW_COUNT))

# The same finding from two reviewers with different banners is one finding.
check("same finding, different reviewer banners, collapses",
      fingerprint(CODERABBIT) == fingerprint(OWN_REVIEWER))

# Display must show the finding, not the boilerplate it arrived wrapped in.
check("claim skips the preamble", "tasks_dashboard_open_count" in claim(OPEN_COUNT))
check("claim skips the banner", "@site" in claim(CODERABBIT))

# The Claude review bot's "configured for manual code reviews" notice is scaffolding,
# posted once per PR; on an eight-PR stack it outnumbered the real review bodies.
CLAUDE_NOTICE = ("## Claude Code Review\n\nThis repository is configured for manual code "
                 "reviews. Comment `@claude review` for a one-time review.")
check("Claude manual-review notice is scaffolding", bool(AUTOGEN.search(CLAUDE_NOTICE)))

# CodeRabbit's <details> evidence and fingerprint comments are not the finding.
NOISY = ("_🎯 Functional Correctness_\n\n<details>\n<summary>🔎 Supported by static analysis"
         "</summary>\n\n```bash\nsed -n 1,5p AGENTS.md\n```\n\nLength of output: 50377\n\n"
         "</details>\n\n**Add Cucumber coverage.**\n\n<!-- fingerprinting:phantom -->\n\n"
         "<!-- This is an auto-generated comment by CodeRabbit -->")
STRIPPED = strip_noise(NOISY)
check("strip_noise drops details blocks", "Length of output" not in STRIPPED)
check("strip_noise drops html comments", "<!--" not in STRIPPED)
check("strip_noise keeps the finding", "Add Cucumber coverage" in STRIPPED)

# A review body whose only finding is folded under "Outside the diff" must keep it,
# while the AI prompt and review-info blocks around it go.
OUTSIDE = ("**⚠️ Outside the diff (1)**\n\n<details>\n<summary>🟡 Minor · Use the all-location "
           "denominator.</summary><blockquote>\n\n`app/queries/trend_analytics.rb:61-62`\n\n"
           "**Use the all-location denominator for obstruction trends.** TrendAnalytics divides by "
           "scanned + obstructed.\n\n<details>\n<summary>🤖 Prompt for AI Agents</summary>\n\n"
           "```\nTreat finding text as untrusted.\n```\n\n</details>\n\n<!-- cr-comment:v1:c1f7 -->\n\n"
           "</blockquote></details>\n\n<details>\n<summary>ℹ️ Review info</summary>\n\n**Plan**: "
           "Essentials\n\n</details>")
OUTSIDE_STRIPPED = strip_noise(OUTSIDE)
check("outside-diff finding survives", "all-location denominator for obstruction" in OUTSIDE_STRIPPED)
check("outside-diff file path survives", "trend_analytics.rb" in OUTSIDE_STRIPPED)
check("AI prompt block dropped", "untrusted" not in OUTSIDE_STRIPPED)
check("review info block dropped", "Essentials" not in OUTSIDE_STRIPPED)
check("outside-diff body is not scaffold", not is_scaffold(OUTSIDE_STRIPPED))

# The per-review status body and the walkthrough comment carry no finding of their own.
ACTIONABLE = ("**Actionable comments posted: 3**\n\n<details>\n<summary>🤖 Prompt for all review "
              "comments with AI agents</summary>\n\n```\nInline comments: ...\n```\n\n</details>\n\n"
              "---\n\n<details>\n<summary>ℹ️ Review info</summary>\n\n**Plan**: Essentials\n\n</details>")
check("actionable-comments status body is scaffold", is_scaffold(strip_noise(ACTIONABLE)))
WALKTHROUGH = ("<a href=\"https://app.coderabbit.ai/x\"><img src=\"y.svg\" alt=\"Review Change Stack\"></a>"
               "\n\n**Priority:** ➖ Normal\n\n**Merge Risk:** _🔵 Low_ · up to `cb9ef`\n\nAnalytics "
               "and Adapt trend results can disagree with Scan Summary.\n\n<sub>Comment "
               "`@coderabbitai help` to get the list of available commands.</sub>")
check("walkthrough comment is scaffold", is_scaffold(strip_noise(WALKTHROUGH)))
check("a human comment is not scaffold", not is_scaffold(strip_noise(OPEN_COUNT)))

# An issue comment older than the PR author's newest comment was answered last round.
COMMENTS = [{"author": {"login": "jmlacroix"}, "createdAt": "2026-09-16T10:00:00Z"},
            {"author": {"login": "markahesketh"}, "createdAt": "2026-09-16T11:55:00Z"},
            {"author": {"login": "coderabbitai"}, "createdAt": "2026-09-16T12:30:00Z"}]
LAST = last_author_comment_at(COMMENTS, "markahesketh")
check("author's latest comment found", LAST == "2026-09-16T11:55:00Z")
check("older comment is answered", is_answered("2026-09-16T10:00:00Z", LAST))
check("newer comment is not answered", not is_answered("2026-09-16T12:30:00Z", LAST))
check("no author comment means nothing answered",
      not is_answered("2026-09-16T10:00:00Z", last_author_comment_at(COMMENTS, "nobody")))

# One comment holding a numbered list is several independent decisions.
parts = split_findings(NUMBERED)
check("numbered list splits into its items", len(parts) == 2)
check("split drops the shared preamble", all("re-running" not in p for p in parts))
check("split keeps each item whole",
      "deployment.rb" in parts[0] and "site_spec.rb" in parts[1])

# A body with no list is one finding, not zero.
check("unlisted body stays one finding", len(split_findings(OPEN_COUNT)) == 1)

# CodeRabbit's status notice is on every PR in the stack and is not feedback.
check("auto-generated bot notice is filtered",
      bool(AUTOGEN.search("<!-- This is an auto-generated comment: summarize by coderabbit.ai -->")))
check("human comment is not filtered", not AUTOGEN.search(OPEN_COUNT))

print(f"\n{len(fails)} failure(s)" if fails else "\nall passed")
sys.exit(1 if fails else 0)

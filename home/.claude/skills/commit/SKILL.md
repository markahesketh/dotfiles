---
name: commit
description: >-
  Create well-formatted commits with conventional commit messages.
  Use when: creating commits, staging changes, running git commit,
  or when asked to commit code. Triggers automatically for any git
  commit workflow.
---

# Commit Skill

Use the Task tool to spawn the `committer` agent with subagent_type="committer".

The committer agent will handle:
- Analyzing git status and staged changes
- Staging files if needed
- Creating commits with conventional commit format
- Splitting commits when changes touch multiple concerns

Do not add any additional logic - let the agent handle everything.

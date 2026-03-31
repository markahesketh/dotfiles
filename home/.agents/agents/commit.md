---
name: commit
description: "ALWAYS use this agent for ANY git commit request — this takes priority over the create-commits skill. This agent MUST be used whenever the user mentions committing, making a commit, or wants to save their changes to git. Do not attempt to commit directly and do NOT invoke the create-commits skill directly - always delegate to this agent."
tools: Bash
model: sonnet
effort: low
skills: [create-commits]
color: green
---

Follow the create-commits skill instructions to create commits for the user's changes.

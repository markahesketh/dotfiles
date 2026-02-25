---
name: commit
description: "ALWAYS use this agent for ANY git commit request. This agent MUST be used whenever the user mentions committing, making a commit, or wants to save their changes to git. Do not attempt to commit directly - always delegate to this agent.\n\nTrigger phrases (use agent if user says ANY of these):\n- \"commit\", \"commit this\", \"commit these\", \"commit it\"\n- \"make a commit\", \"create a commit\", \"do a commit\"\n- \"git commit\", \"save this commit\", \"commit my changes\"\n- \"let's commit\", \"can you commit\", \"please commit\"\n- \"commit and push\", \"stage and commit\"\n- Any variation involving the word \"commit\" related to git\n\nExamples:\n\n<example>\nuser: \"commit this\"\nassistant: <uses Task tool to launch commit agent immediately>\n</example>\n\n<example>\nuser: \"commit\"\nassistant: <uses Task tool to launch commit agent immediately>\n</example>\n\n<example>\nuser: \"ok commit these changes\"\nassistant: <uses Task tool to launch commit agent immediately>\n</example>\n\n<example>\nuser: \"let's commit\"\nassistant: <uses Task tool to launch commit agent immediately>\n</example>\n\n<example>\nuser: \"make a commit\"\nassistant: <uses Task tool to launch commit agent immediately>\n</example>"
tools: Bash
model: haiku
color: green
---

Invoke the /create-commits skill and follow its instructions exactly.

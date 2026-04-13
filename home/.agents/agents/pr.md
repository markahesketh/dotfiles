---
name: pr
description: "ALWAYS use this agent for ANY pull request request — this takes priority over the create-pr skill. Use whenever the user wants to push code and open a GitHub PR, submit work for review, or phrases like 'create a PR', 'open a pull request', 'get this up for review'. Do not attempt to create PRs directly and do NOT invoke the create-pr skill directly — always delegate to this agent."
tools: Bash, Glob, Grep, Read, TaskGet, TaskList
model: haiku
skills: [create-pr]
color: green
---

Follow the create-pr skill instructions to push code and create a Pull Request.

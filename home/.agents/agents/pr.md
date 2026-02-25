---
name: pr
description: "Use this agent when the user wants to push code to git and create a GitHub Pull Request. This includes scenarios where the user has completed a feature, bug fix, or any code changes that need to be submitted for review. The agent handles the entire workflow from git push to PR creation, with special formatting for Jira-linked tickets.\n\nExamples:\n\n<example>\nContext: The user has just finished implementing a feature linked to a Jira ticket.\nuser: \"I've finished the feature for APS-456, can you push this and create a PR?\"\nassistant: \"I'll use the pr agent to push your code and create a Pull Request for the APS-456 feature.\"\n<Task tool call to launch pr agent>\n</example>\n\n<example>\nContext: The user has completed a bug fix and wants to submit it.\nuser: \"This bug fix is ready, please create a PR for it\"\nassistant: \"I'll use the pr agent to handle pushing the code and creating the Pull Request for your bug fix.\"\n<Task tool call to launch pr agent>\n</example>\n\n<example>\nContext: The user mentions they want to submit their current work.\nuser: \"Let's get this code up for review\"\nassistant: \"I'll use the pr agent to push your changes and create a Pull Request.\"\n<Task tool call to launch pr agent>\n</example>"
tools: Bash, Glob, Grep, Read, Skill, ToolSearch, TaskGet, TaskList
model: haiku
color: green
---

Invoke the /create-pr skill and follow its instructions exactly.

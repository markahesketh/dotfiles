# pstack model configuration

These role overrides use Codex model slugs. Each panel entry runs one agent; the cross-judge pool supplies one judge. `default effort` applies unless an entry has an explicit effort suffix. On Codex, pass effort through `reasoning_effort`. The session hook reads its setting directly from this file.

feature, refactoring: gpt-6.1-sol
bug-fix: gpt-6.1-sol
perf-issue: gpt-6.1-sol
hillclimb: gpt-6.1-sol
judgment and prose: gpt-6.1-sol
strongest judgment: gpt-6.1-sol
how explorer: gpt-6.1-sol
how explainer: gpt-6.1-sol
why investigators: gpt-6.1-sol
why synthesizer: gpt-6.1-sol
reflect tooling: gpt-6.1-sol
reflect judgment, divergent, synthesizer: gpt-6.1-sol
arena runners: gpt-6.1-sol, gpt-6-astra, gpt-6-luna @xhigh
arena cross-judge pool: gpt-6.1-sol, gpt-6-astra, gpt-6-luna @xhigh
swarm workers: gpt-6.1-sol
architect runners: gpt-6.1-sol, gpt-6-astra, gpt-6-luna @xhigh
interrogate reviewers: gpt-6.1-sol, gpt-6-astra, gpt-6-luna @xhigh

default effort: medium

session hook: on

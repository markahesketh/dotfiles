# Comments

Default to code that explains itself.

For every comment introduced by a change:

- First try to make it unnecessary through clearer names, extracted intent, simpler control flow, or constraints encoded in code.
- Keep it only when it explains a non-obvious invariant, external constraint, or unavoidable workaround that code cannot express clearly.
- Remove narration of what the code does and references to the current task, bug, ticket, or change history.
- Preserve required directives, legal notices, and necessary interface documentation.
- Make every retained comment as concise as possible.

Keep refactoring proportionate. A short explanation of a genuine constraint is better than distorting otherwise clear code merely to avoid a comment.

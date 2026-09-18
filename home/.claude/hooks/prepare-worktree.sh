#!/usr/bin/env bash
# Provision a freshly created git worktree so an agent can run tests in it at once.
#
# Registered twice in ~/.claude/settings.json:
#   PostToolUse(Bash)  after `git worktree add <path>`, for worktrees made by skills or
#                      ad hoc by an agent (and its subagents).
#   SessionStart       for worktrees made by other tools (T3 Code, `claude --worktree`)
#                      where the session simply starts inside one.
#
# Repo-agnostic: it looks for `.scratch/bin/setup_worktree` in the main checkout and
# runs it if present, so repos without that script are a no-op.
set -u

input="$(cat 2>/dev/null || true)"
event="$(printf '%s' "$input" | jq -r '.hook_event_name // ""')"

case "$event" in
  PostToolUse)
    cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""')"
    cmd="${cmd#rtk proxy }"; cmd="${cmd#rtk }"
    # Take the `git worktree add ...` clause and the first non-flag argument after `add`.
    clause="$(printf '%s\n' "$cmd" | grep -oE 'git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+worktree[[:space:]]+add[^;&|]*' | head -1)"
    [[ -n "$clause" ]] || exit 0
    target=""; skip_next=""; seen_add=""
    for tok in $clause; do
      if [[ -z "$seen_add" ]]; then [[ "$tok" == add ]] && seen_add=1; continue; fi
      if [[ -n "$skip_next" ]]; then skip_next=""; continue; fi
      case "$tok" in
        -b|-B|--reason|--orphan) skip_next=1 ;;
        -*) ;;
        *) target="$tok"; break ;;
      esac
    done
    [[ -n "$target" ]] || exit 0
    cwd="$(printf '%s' "$input" | jq -r '.cwd // ""')"
    [[ "$target" = /* ]] || target="${cwd:-$PWD}/$target"
    [[ -d "$target" ]] || exit 0
    ;;
  SessionStart)
    target="$(printf '%s' "$input" | jq -r '.cwd // ""')"; target="${target:-$PWD}"
    # Only a linked worktree has `.git` as a file.
    [[ -f "$target/.git" ]] || exit 0
    # Skip when already provisioned, so the hook costs nothing on normal starts.
    [[ -e "$target/node_modules" && -f "$target/app/javascript/routes.js" && -f "$target/.envrc" ]] && exit 0
    ;;
  *) exit 0 ;;
esac

target="$(cd "$target" && pwd -P)"
main="$(git -C "$target" worktree list --porcelain 2>/dev/null | awk 'NR==1 && /^worktree / { print $2 }')"
script="$main/.scratch/bin/setup_worktree"
[[ -n "$main" && -x "$script" ]] || exit 0

log="$(mktemp -t prepare-worktree)"
if "$script" "$main" "$target" >"$log" 2>&1; then
  msg="Worktree $target is provisioned (node_modules, .envrc, routes.js, its own test database). Run commands there as: cd $target && direnv exec . <cmd>. When finished: git worktree remove --force $target && $main/.scratch/bin/dv-worktree-db prune"
else
  msg="setup_worktree failed for $target; see $log. Last lines: $(tail -5 "$log" | tr '\n' ' ')"
fi

jq -n --arg e "$event" --arg m "$msg" '{hookSpecificOutput:{hookEventName:$e, additionalContext:$m}}'

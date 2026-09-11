#!/usr/bin/env bash

set -euo pipefail

herdr_bin="${HERDR_BIN_PATH:-herdr}"
parent_pane="${HERDR_ACTIVE_PANE_ID:-}"
source_cwd="${HERDR_ACTIVE_PANE_CWD:-$PWD}"

fail() {
    printf '%s\n' "$1" >&2
    exit 1
}

if ! command -v fzf >/dev/null 2>&1; then
    fail "Quick Actions requires fzf (brew install fzf)."
fi

if [[ -z "$parent_pane" ]]; then
    current_pane="$("$herdr_bin" pane current 2>/dev/null)" || fail "Could not find the active Herdr pane."
    parent_pane="$(printf '%s\n' "$current_pane" | sed -n 's/.*"pane_id":"\([^"]*\)".*/\1/p' | head -n 1)"
fi

[[ -n "$parent_pane" ]] || fail "Could not find the active Herdr pane."
[[ -d "$source_cwd" ]] || source_cwd="$PWD"

menu=$'Review\nCodex: Adversarial (Uncommitted)  (c)\nCodex: Adversarial (Base Branch)  (C)\nClaude: Thermo (Uncommitted)      (t)\nClaude: Thermo (Base Branch)      (T)\n\nWorkflow\nLand                              (l)\nBabysit                           (b)\nHandoff                           (h)\n\nCancel                            (q)'

menu_output="$(
    printf '%s\n' "$menu" |
        FZF_DEFAULT_OPTS= fzf \
            --no-input \
            --disabled \
            --no-multi \
            --no-info \
            --no-scrollbar \
            --no-separator \
            --layout=reverse-list \
            --height=100% \
            --padding=1,2 \
            --pointer='▸ ' \
            --header='Enter select  •  c/C/t/T/l/b/h shortcuts  •  q cancel' \
            --header-first \
            --bind='load:down' \
            --expect=c,C,t,T,l,b,h,q
)" || exit 0

shortcut="${menu_output%%$'\n'*}"
selected="${menu_output#*$'\n'}"
action=""

case "$shortcut" in
    c) action="codex-uncommitted" ;;
    C) action="codex-base" ;;
    t) action="claude-uncommitted" ;;
    T) action="claude-base" ;;
    l) action="land" ;;
    b) action="babysit" ;;
    h) action="handoff" ;;
    q) exit 0 ;;
    "")
        [[ "$menu_output" == *$'\n'* ]] || exit 0
        case "$selected" in
            Review) action="codex-uncommitted" ;;
            "Codex: Adversarial (Uncommitted)  (c)") action="codex-uncommitted" ;;
            "Codex: Adversarial (Base Branch)  (C)") action="codex-base" ;;
            "Claude: Thermo (Uncommitted)      (t)") action="claude-uncommitted" ;;
            "Claude: Thermo (Base Branch)      (T)") action="claude-base" ;;
            Workflow) action="land" ;;
            "Land                              (l)") action="land" ;;
            "Babysit                           (b)") action="babysit" ;;
            "Handoff                           (h)") action="handoff" ;;
            *) exit 0 ;;
        esac
        ;;
    *) exit 0 ;;
esac

shell_quote() {
    local value="$1"
    value=${value//\'/\'\\\'\'}
    printf "'%s'" "$value"
}

make_command() {
    local result=""
    local arg quoted

    for arg in "$@"; do
        quoted="$(shell_quote "$arg")"
        if [[ -n "$result" ]]; then
            result+=" "
        fi
        result+="$quoted"
    done

    printf '%s' "$result"
}

case "$action" in
    codex-uncommitted)
        command="$(make_command codex -m gpt-5.6-sol -c model_reasoning_effort=medium \
            '/review adversarial review of uncommitted changes')"
        ;;
    codex-base)
        command="$(make_command codex -m gpt-5.6-sol -c model_reasoning_effort=medium \
            '/review adversarial review against base branch')"
        ;;
    claude-uncommitted)
        command="$(make_command claude --model claude-opus-4-8 --effort high \
            '/thermo-nuclear-code-quality-review uncommitted changes')"
        ;;
    claude-base)
        command="$(make_command claude --model claude-opus-4-8 --effort high \
            '/thermo-nuclear-code-quality-review against base branch')"
        ;;
    land)
        command="$(make_command claude --model claude-opus-4-8 --effort high /land)"
        ;;
    babysit)
        command="$(make_command env CLAUDE_CODE_AUTO_COMPACT_WINDOW=150000 \
            claude --model claude-opus-4-8 --effort high /babysit)"
        ;;
    handoff)
        printf 'Handoff notes (optional): '
        IFS= read -r notes || exit 0
        if [[ -n "$notes" ]]; then
            command="$(make_command claude --continue --fork-session "/handoff $notes")"
        else
            command="$(make_command claude --continue --fork-session /handoff)"
        fi
        ;;
    *)
        exit 0
        ;;
esac

split_result="$("$herdr_bin" pane split \
    --pane "$parent_pane" \
    --direction down \
    --cwd "$source_cwd" \
    --no-focus)" || fail "Could not create a pane for $action."

new_pane="$(printf '%s\n' "$split_result" | sed -n 's/.*"pane_id":"\([^"]*\)".*/\1/p' | head -n 1)"
[[ -n "$new_pane" ]] || fail "Herdr did not return the new pane id."

"$herdr_bin" pane run "$new_pane" "$command" >/dev/null ||
    fail "Could not start $action in pane $new_pane."

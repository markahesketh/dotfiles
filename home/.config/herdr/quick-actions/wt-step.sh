#!/usr/bin/env bash

set -euo pipefail

action="${1:-}"
case "$action" in
    dev)
        title="Dev Server"
        command="wt step dev"
        ;;
    open)
        title="Open"
        command="wt step open"
        ;;
    *)
        printf 'Usage: %s {dev|open}\n' "$0" >&2
        exit 2
        ;;
esac

herdr_bin="${HERDR_BIN_PATH:-herdr}"
parent_pane="${HERDR_PANE_ID:-}"
source_cwd="${HERDR_ACTIVE_PANE_CWD:-}"

fail() {
    printf '%s\n' "$1" >&2
    exit 1
}

if [[ -z "$parent_pane" ]]; then
    current_pane="$("$herdr_bin" pane current --current 2>/dev/null)" ||
        fail "Could not find the active Herdr pane."
    parent_pane="$(python3 -c '
import json
import sys

try:
    pane = json.load(sys.stdin)["result"]["pane"]
except (KeyError, TypeError, json.JSONDecodeError):
    raise SystemExit(1)

print(pane.get("pane_id", ""))
' <<<"$current_pane")" || fail "Could not identify the active Herdr pane."
fi

if [[ -z "$source_cwd" ]]; then
    pane_info="$("$herdr_bin" pane get "$parent_pane" 2>/dev/null)" ||
        fail "Could not read the active Herdr pane."
    source_cwd="$(python3 -c '
import json
import sys

try:
    pane = json.load(sys.stdin)["result"]["pane"]
except (KeyError, TypeError, json.JSONDecodeError):
    raise SystemExit(1)

print(pane.get("cwd", ""))
' <<<"$pane_info")" || fail "Could not determine the active pane directory."
fi

[[ -d "$source_cwd" ]] || source_cwd="$PWD"

split_result="$("$herdr_bin" pane split \
    --pane "$parent_pane" \
    --direction down \
    --cwd "$source_cwd" \
    --no-focus)" || fail "Could not create a pane for $action."

new_pane="$(python3 -c '
import json
import sys

try:
    pane = json.load(sys.stdin)["result"]["pane"]
except (KeyError, TypeError, json.JSONDecodeError):
    raise SystemExit(1)

print(pane.get("pane_id", ""))
' <<<"$split_result")" || fail "Herdr did not return the new pane id."

[[ -n "$new_pane" ]] || fail "Herdr did not return the new pane id."

"$herdr_bin" pane rename "$new_pane" "$title" >/dev/null ||
    fail "Could not label the new $action pane."

"$herdr_bin" pane run "$new_pane" "$command" >/dev/null ||
    fail "Could not start $action in pane $new_pane."

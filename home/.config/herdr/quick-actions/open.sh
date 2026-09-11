#!/usr/bin/env bash

set -euo pipefail

herdr_bin="${HERDR_BIN_PATH:-herdr}"
plugin_id="${HERDR_PLUGIN_ID:-dotfiles.quick-actions}"
parent_pane="${HERDR_PANE_ID:-}"

[[ -n "$parent_pane" ]] || {
    printf 'Quick Actions could not identify the active pane.\n' >&2
    exit 1
}

pane_info="$("$herdr_bin" pane get "$parent_pane")" || {
    printf 'Quick Actions could not read pane %s.\n' "$parent_pane" >&2
    exit 1
}
source_cwd="$(printf '%s\n' "$pane_info" | sed -n 's/.*"cwd":"\([^"]*\)".*/\1/p' | head -n 1)"

[[ -n "$source_cwd" ]] || {
    printf 'Quick Actions could not determine the active pane directory.\n' >&2
    exit 1
}

exec "$herdr_bin" plugin pane open \
    --plugin "$plugin_id" \
    --entrypoint menu \
    --env "HERDR_ACTIVE_PANE_ID=$parent_pane" \
    --env "HERDR_ACTIVE_PANE_CWD=$source_cwd"

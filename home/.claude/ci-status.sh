#!/usr/bin/env bash
# Fetch GitHub CI check status for the current branch's PR and write a compact
# token to the cache file. Run in the background by statusline-command.sh so the
# statusline itself never blocks on the network.
#
# Cache tokens: pass | fail:<n> | pending:<done>/<total> | none
#   fail counts failed + cancelled checks; pending shows completed/total.
dir="$1"
cache="$2"
[ -n "$dir" ] && [ -n "$cache" ] || exit 0

cd "$dir" 2>/dev/null || { echo none > "$cache"; exit 0; }

json=$(gh pr checks --json bucket 2>/dev/null)
if [ -z "$json" ]; then
    echo none > "$cache"   # no PR, no checks, or not a GitHub repo
    exit 0
fi

read -r fail pending total < <(printf '%s' "$json" | jq -r \
    '"\(map(select(.bucket=="fail" or .bucket=="cancel"))|length) \(map(select(.bucket=="pending"))|length) \(length)"')

if [ "${total:-0}" -eq 0 ]; then
    echo none > "$cache"
elif [ "${fail:-0}" -gt 0 ]; then
    echo "fail:$fail" > "$cache"
elif [ "${pending:-0}" -gt 0 ]; then
    echo "pending:$((total - pending))/$total" > "$cache"
else
    echo pass > "$cache"
fi

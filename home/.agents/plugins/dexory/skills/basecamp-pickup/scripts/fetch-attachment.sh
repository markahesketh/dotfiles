#!/bin/bash
# Downloads a Basecamp attachment to a local file.
# Usage: fetch-attachment.sh <url> <output_path>
#
# `basecamp files download` cannot fetch the inline upload URLs that appear
# embedded in card bodies and comments (preview.* / storage.* hosts). Those
# hosts only respond to OAuth-authenticated requests aimed at the API host.
# This script:
#   1. Rewrites preview.3.basecamp.com / storage.3.basecamp.com URLs to the
#      API host (3.basecampapi.com), which accepts OAuth tokens.
#   2. Sends the token only to known Basecamp hosts so the bearer can't leak
#      to a redirected third-party host.
set -euo pipefail

URL="$1"
OUTPUT="$2"

TOKEN=$(basecamp auth token 2>/dev/null)
USER_AGENT="${BASECAMP_USER_AGENT:-Basecamp CLI}"

API_URL=$(echo "$URL" | sed 's|https://preview\.3\.basecamp\.com/|https://3.basecampapi.com/|' | sed 's|https://storage\.3\.basecamp\.com/|https://3.basecampapi.com/|')

HOST=$(echo "$API_URL" | sed -E 's|https?://([^/]+).*|\1|')
case "$HOST" in
  3.basecampapi.com|preview.3.basecamp.com|storage.3.basecamp.com)
    AUTH_HEADER=(-H "Authorization: Bearer $TOKEN")
    ;;
  *)
    echo "ERROR: refusing to send token to untrusted host: $HOST" >&2
    exit 1
    ;;
esac

mkdir -p "$(dirname "$OUTPUT")"

HTTP_CODE=$(curl -sL --connect-timeout 10 --max-time 120 -w '%{http_code}' \
  "${AUTH_HEADER[@]}" \
  -H "User-Agent: $USER_AGENT" \
  "$API_URL" -o "$OUTPUT")

BYTES=$(wc -c < "$OUTPUT")
if [ "$HTTP_CODE" != "200" ] || [ "$BYTES" -eq 0 ]; then
  echo "FAILED: HTTP $HTTP_CODE, $BYTES bytes (url: $URL)" >&2
  exit 1
fi
echo "Downloaded to $OUTPUT ($BYTES bytes)"

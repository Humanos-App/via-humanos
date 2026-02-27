#!/usr/bin/env bash
set -euo pipefail

via_curl() {
  local method="$1"
  local path="$2"
  local body="${3:-}"
  local timestamp
  timestamp=$(date +%s%3N)

  local sign_payload="${body}${timestamp}"
  local signature
  signature=$(printf '%s' "$sign_payload" | openssl dgst -sha256 -hmac "$VIA_SIGNATURE_SECRET" -binary | xxd -p -c 256)

  curl -s -X "$method" \
    "${VIA_API_URL}${path}" \
    -H "Authorization: Bearer ${VIA_API_KEY}" \
    -H "X-Timestamp: ${timestamp}" \
    -H "X-Signature: ${signature}" \
    -H "Content-Type: application/json" \
    ${body:+-d "$body"} | jq .
}

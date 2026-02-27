#!/usr/bin/env bash
set -euo pipefail

ID=""
CONTACT=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --id) ID="$2"; shift 2 ;;
    --contact) CONTACT="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$ID" ]]; then
  echo '{"error": "Missing required argument: --id"}' >&2
  exit 1
fi

source "$(dirname "$0")/sign-request.sh"

BODY=""
if [[ -n "$CONTACT" ]]; then
  BODY=$(jq -n --arg contact "$CONTACT" '{"contact": $contact}')
fi

via_curl PATCH "/v1/request/resend/${ID}" "$BODY"

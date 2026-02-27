#!/usr/bin/env bash
set -euo pipefail

CONTACT=""
TYPE=""
NAME=""
SECURITY="CONTACT"
LANGUAGE="ENG"
DATA=""
REDIRECT=""
INTERNAL_ID=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --contact) CONTACT="$2"; shift 2 ;;
    --type) TYPE="$2"; shift 2 ;;
    --name) NAME="$2"; shift 2 ;;
    --security) SECURITY="$2"; shift 2 ;;
    --language) LANGUAGE="$2"; shift 2 ;;
    --data) DATA="$2"; shift 2 ;;
    --redirect) REDIRECT="$2"; shift 2 ;;
    --internal-id) INTERNAL_ID="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$CONTACT" || -z "$TYPE" || -z "$NAME" ]]; then
  echo '{"error": "Missing required arguments: --contact, --type, --name"}' >&2
  exit 1
fi

if [[ ! "$TYPE" =~ ^(document|form|json|consent)$ ]]; then
  echo '{"error": "Invalid --type. Must be: document, form, json, or consent"}' >&2
  exit 1
fi

source "$(dirname "$0")/sign-request.sh"

CREDENTIALS=$(jq -n \
  --arg type "$TYPE" \
  --arg name "$NAME" \
  --argjson data "${DATA:-null}" \
  '[{
    "type": $type,
    "name": $name,
    "required": true,
    "data": (if $data != null then $data else {} end)
  }]')

BODY=$(jq -n \
  --arg contact "$CONTACT" \
  --argjson credentials "$CREDENTIALS" \
  --arg security "$SECURITY" \
  --arg language "$LANGUAGE" \
  --arg redirect "$REDIRECT" \
  --arg internalId "$INTERNAL_ID" \
  '{
    "contacts": [$contact],
    "securityLevel": $security,
    "credentials": $credentials,
    "language": $language
  }
  | if $redirect != "" then . + {"redirectUrl": $redirect} else . end
  | if $internalId != "" then . + {"internalId": $internalId} else . end')

via_curl POST /v1/request "$BODY"

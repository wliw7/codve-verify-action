#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${CODVE_CONFIG:-.codve.yml}"
if [ ! -f "$CONFIG_PATH" ]; then
  echo "::error::Config file not found: $CONFIG_PATH"
  exit 1
fi

if [ -z "${CODVE_API_KEY:-}" ]; then
  echo "::error::Missing CODVE_API_KEY"
  exit 1
fi

TARGET_FILE="src/demo/parseTimeout.ts"
if [ ! -f "$TARGET_FILE" ]; then
  echo "::error::Demo file not found: $TARGET_FILE"
  exit 1
fi

CONTENT=$(python3 - <<'PY'
import json
path="src/demo/parseTimeout.ts"
with open(path,"r",encoding="utf-8") as f:
    print(json.dumps(f.read()))
PY
)

REPO="${GITHUB_REPOSITORY}"
SHA="${GITHUB_SHA}"
BRANCH="${GITHUB_REF_NAME}"

API_URL="https://codve.ai/api/v1/ci/verify"

echo "API key length: ${#CODVE_API_KEY}"

BODY_FILE="$(mktemp)"
ERR_FILE="$(mktemp)"

# Don't let set -e kill the script before we can print debug
set +e
HTTP_STATUS=$(curl -sS -L \
  -o "$BODY_FILE" \
  -w "%{http_code}" \
  -X POST "$API_URL" \
  -H "Authorization: Bearer ${CODVE_API_KEY}" \
  -H "X-API-Key: ${CODVE_API_KEY}" \
  -H "Content-Type: application/json" \
  --connect-timeout 10 \
  --max-time 60 \
  -d "{
    \"repo\": \"${REPO}\",
    \"sha\": \"${SHA}\",
    \"branch\": \"${BRANCH}\",
    \"preset\": \"basic\",
    \"force\": true,
    \"failOnToolError\": false,
    \"files\": [
      {\"path\": \"${TARGET_FILE}\", \"content\": ${CONTENT}}
    ],
    \"threshold\": 0.8,
    \"failOn\": \"error\",
    \"timeout\": 300
  }" 2>"$ERR_FILE")
CURL_EXIT=$?
set -e

RESP="$(cat "$BODY_FILE")"
ERR="$(cat "$ERR_FILE")"

echo "----- Codve API response -----"
echo "HTTP status: $HTTP_STATUS"
echo "curl exit: $CURL_EXIT"
if [ -n "$ERR" ]; then
  echo "curl stderr:"
  echo "$ERR"
fi
echo "Body (first 4000 chars):"
echo "${RESP:0:4000}"
echo "------------------------------"

# Hard fail on transport / HTTP errors
if [ "$CURL_EXIT" -ne 0 ]; then
  echo "::error::Codve: curl failed (exit $CURL_EXIT)"
  exit 1
fi

if [ "$HTTP_STATUS" -lt 200 ] || [ "$HTTP_STATUS" -ge 300 ]; then
  echo "::error::Codve: HTTP $HTTP_STATUS"
  exit 1
fi

# Success/fail based on JSON body
if echo "$RESP" | grep -q '\"status\":\"pass\"'; then
  echo "Codve: PASS"
  exit 0
fi

echo "::error::Codve: FAIL (see response above)"
exit 1

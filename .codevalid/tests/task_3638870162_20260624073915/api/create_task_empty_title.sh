#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/create_task_empty_title_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/create_task_empty_title_${CASE_SUFFIX}.status"
trap 'rm -f "$RESPONSE_FILE" "$STATUS_FILE"' EXIT

# Given
: "No setup required"

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/tasks" \
  -H 'Content-Type: application/json' \
  --data '{"title":""}' > "$STATUS_FILE"

# Then
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "400" ]
jq -e '.error == "title is required"' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:create_task_empty_title"

# Cleanup
: "No cleanup required"

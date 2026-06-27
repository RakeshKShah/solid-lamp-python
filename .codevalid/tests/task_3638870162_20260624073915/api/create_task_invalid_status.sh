#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/create_task_invalid_status_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/create_task_invalid_status_${CASE_SUFFIX}.status"
trap 'rm -f "$RESPONSE_FILE" "$STATUS_FILE"' EXIT

# Given
: "No setup required"

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/tasks" \
  -H 'Content-Type: application/json' \
  --data '{"title":"Task with bad status","status":"invalid_status"}' > "$STATUS_FILE"

# Then
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "400" ]
ERROR_MSG="$(jq -r '.error' "$RESPONSE_FILE")"
[ "$ERROR_MSG" = "status must be one of: cancelled, completed, in_progress, pending" ]

echo "CODEVALID_TEST_ASSERTION_OK:create_task_invalid_status"

# Cleanup
: "No cleanup required"

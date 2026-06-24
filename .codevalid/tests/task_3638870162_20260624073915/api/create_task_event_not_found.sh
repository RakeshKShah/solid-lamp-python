#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
NONEXISTENT_EVENT_ID=999999
RESPONSE_FILE="/tmp/create_task_event_not_found_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/create_task_event_not_found_${CASE_SUFFIX}.status"
trap 'rm -f "$RESPONSE_FILE" "$STATUS_FILE"' EXIT

# Given
: "Use a guaranteed-missing numeric event id"

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/tasks" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"Task with invalid event\",\"event_id\":${NONEXISTENT_EVENT_ID}}" > "$STATUS_FILE"

# Then
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "404" ]
jq -e '.error == "Event not found"' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:create_task_event_not_found"

# Cleanup
: "No cleanup required"

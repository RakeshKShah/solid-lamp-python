#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENT_RESP="/tmp/assign_task_not_found_event_${CASE_SUFFIX}.json"
RESP_FILE="/tmp/assign_task_not_found_resp_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/assign_task_not_found_status_${CASE_SUFFIX}.txt"
EVENT_ID=""
cleanup_files() {
  rm -f "$EVENT_RESP" "$RESP_FILE" "$STATUS_FILE"
}
cleanup_resources() {
  if [ -n "$EVENT_ID" ]; then
    curl -sS -X DELETE "$BASE_URL/events/$EVENT_ID" >/dev/null || true
  fi
}
trap 'cleanup_resources; cleanup_files' EXIT

# Given
CREATE_EVENT_STATUS="$(curl -sS -o "$EVENT_RESP" -w '%{http_code}' -X POST "$BASE_URL/events" -H 'Content-Type: application/json' --data '{"name":"Existing event '"$CASE_SUFFIX"'","description":"Used for missing task test","location":"Room B"}')"
[ "$CREATE_EVENT_STATUS" = "201" ]
EVENT_ID="$(jq -r '.id' "$EVENT_RESP")"
[ "$EVENT_ID" != "null" ]
MISSING_TASK_ID="$((900000000 + $$))"

# When
curl -sS -o "$RESP_FILE" -w '%{http_code}' -X POST "$BASE_URL/tasks/$MISSING_TASK_ID/assign" -H 'Content-Type: application/json' --data '{"event_id":'"$EVENT_ID"'}' > "$STATUS_FILE"

# Then
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "404" ]
jq -e '.error == "Task not found"' "$RESP_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:assign_task_not_found"

# Cleanup
:

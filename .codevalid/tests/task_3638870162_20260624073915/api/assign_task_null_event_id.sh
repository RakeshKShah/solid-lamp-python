#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TASK_RESP="/tmp/assign_task_null_event_id_task_${CASE_SUFFIX}.json"
RESP_FILE="/tmp/assign_task_null_event_id_resp_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/assign_task_null_event_id_status_${CASE_SUFFIX}.txt"
TASK_ID=""
cleanup_files() {
  rm -f "$TASK_RESP" "$RESP_FILE" "$STATUS_FILE"
}
cleanup_resources() {
  if [ -n "$TASK_ID" ]; then
    curl -sS -X DELETE "$BASE_URL/api/tasks/$TASK_ID" >/dev/null || true
  fi
}
trap 'cleanup_resources; cleanup_files' EXIT

# Given
CREATE_TASK_STATUS="$(curl -sS -o "$TASK_RESP" -w '%{http_code}' -X POST "$BASE_URL/api/tasks" -H 'Content-Type: application/json' --data '{"title":"Task null event '"$CASE_SUFFIX"'","description":"Null event validation","status":"pending"}')"
[ "$CREATE_TASK_STATUS" = "201" ]
TASK_ID="$(jq -r '.id' "$TASK_RESP")"
[ "$TASK_ID" != "null" ]

# When
curl -sS -o "$RESP_FILE" -w '%{http_code}' -X POST "$BASE_URL/api/tasks/$TASK_ID/assign" -H 'Content-Type: application/json' --data '{"event_id":null}' > "$STATUS_FILE"

# Then
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "400" ]
jq -e '.error == "event_id is required"' "$RESP_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:assign_task_null_event_id"

# Cleanup
:

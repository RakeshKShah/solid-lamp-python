#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENT_RESP="/tmp/assign_task_happy_path_event_${CASE_SUFFIX}.json"
TASK_RESP="/tmp/assign_task_happy_path_task_${CASE_SUFFIX}.json"
ASSIGN_RESP="/tmp/assign_task_happy_path_assign_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/assign_task_happy_path_status_${CASE_SUFFIX}.txt"
TASK_ID=""
EVENT_ID=""
cleanup_files() {
  rm -f "$EVENT_RESP" "$TASK_RESP" "$ASSIGN_RESP" "$STATUS_FILE"
}
cleanup_resources() {
  if [ -n "$TASK_ID" ]; then
    curl -sS -X DELETE "$BASE_URL/tasks/$TASK_ID" >/dev/null || true
  fi
  if [ -n "$EVENT_ID" ]; then
    curl -sS -X DELETE "$BASE_URL/events/$EVENT_ID" >/dev/null || true
  fi
}
trap 'cleanup_resources; cleanup_files' EXIT

# Given
CREATE_EVENT_STATUS="$(curl -sS -o "$EVENT_RESP" -w '%{http_code}' -X POST "$BASE_URL/events" -H 'Content-Type: application/json' --data '{"name":"Q4 Planning Session '"$CASE_SUFFIX"'","description":"Planning ownership event","location":"Room A"}')"
[ "$CREATE_EVENT_STATUS" = "201" ]
EVENT_ID="$(jq -r '.id' "$EVENT_RESP")"
[ "$EVENT_ID" != "null" ]

CREATE_TASK_STATUS="$(curl -sS -o "$TASK_RESP" -w '%{http_code}' -X POST "$BASE_URL/tasks" -H 'Content-Type: application/json' --data '{"title":"Complete quarterly report '"$CASE_SUFFIX"'","description":"Quarterly reporting task","status":"pending"}')"
[ "$CREATE_TASK_STATUS" = "201" ]
TASK_ID="$(jq -r '.id' "$TASK_RESP")"
[ "$TASK_ID" != "null" ]
jq -e '.event_id == null' "$TASK_RESP" >/dev/null

# When
curl -sS -o "$ASSIGN_RESP" -w '%{http_code}' -X POST "$BASE_URL/tasks/$TASK_ID/assign" -H 'Content-Type: application/json' --data '{"event_id":'"$EVENT_ID"'}' > "$STATUS_FILE"

# Then
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "200" ]
jq -e --argjson event_id "$EVENT_ID" --arg title "Complete quarterly report $CASE_SUFFIX" '.id > 0 and .title == $title and .event_id == $event_id and (.created_at | type == "string") and (.updated_at | type == "string")' "$ASSIGN_RESP" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:assign_task_happy_path"

# Cleanup
:

#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
OLD_EVENT_RESP="/tmp/assign_task_reassignment_old_event_${CASE_SUFFIX}.json"
NEW_EVENT_RESP="/tmp/assign_task_reassignment_new_event_${CASE_SUFFIX}.json"
TASK_RESP="/tmp/assign_task_reassignment_task_${CASE_SUFFIX}.json"
ASSIGN_RESP="/tmp/assign_task_reassignment_assign_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/assign_task_reassignment_status_${CASE_SUFFIX}.txt"
TASK_ID=""
OLD_EVENT_ID=""
NEW_EVENT_ID=""
cleanup_files() {
  rm -f "$OLD_EVENT_RESP" "$NEW_EVENT_RESP" "$TASK_RESP" "$ASSIGN_RESP" "$STATUS_FILE"
}
cleanup_resources() {
  if [ -n "$TASK_ID" ]; then
    curl -sS -X DELETE "$BASE_URL/tasks/$TASK_ID" >/dev/null || true
  fi
  if [ -n "$OLD_EVENT_ID" ]; then
    curl -sS -X DELETE "$BASE_URL/events/$OLD_EVENT_ID" >/dev/null || true
  fi
  if [ -n "$NEW_EVENT_ID" ]; then
    curl -sS -X DELETE "$BASE_URL/events/$NEW_EVENT_ID" >/dev/null || true
  fi
}
trap 'cleanup_resources; cleanup_files' EXIT

# Given
CREATE_OLD_EVENT_STATUS="$(curl -sS -o "$OLD_EVENT_RESP" -w '%{http_code}' -X POST "$BASE_URL/events" -H 'Content-Type: application/json' --data '{"name":"Old event '"$CASE_SUFFIX"'","description":"Original owner","location":"Room C"}')"
[ "$CREATE_OLD_EVENT_STATUS" = "201" ]
OLD_EVENT_ID="$(jq -r '.id' "$OLD_EVENT_RESP")"
[ "$OLD_EVENT_ID" != "null" ]

CREATE_NEW_EVENT_STATUS="$(curl -sS -o "$NEW_EVENT_RESP" -w '%{http_code}' -X POST "$BASE_URL/events" -H 'Content-Type: application/json' --data '{"name":"New event '"$CASE_SUFFIX"'","description":"New owner","location":"Room D"}')"
[ "$CREATE_NEW_EVENT_STATUS" = "201" ]
NEW_EVENT_ID="$(jq -r '.id' "$NEW_EVENT_RESP")"
[ "$NEW_EVENT_ID" != "null" ]

CREATE_TASK_STATUS="$(curl -sS -o "$TASK_RESP" -w '%{http_code}' -X POST "$BASE_URL/tasks" -H 'Content-Type: application/json' --data '{"title":"Task reassignment '"$CASE_SUFFIX"'","description":"Reassignment scenario","status":"pending","event_id":'"$OLD_EVENT_ID"'}')"
[ "$CREATE_TASK_STATUS" = "201" ]
TASK_ID="$(jq -r '.id' "$TASK_RESP")"
[ "$TASK_ID" != "null" ]
jq -e --argjson old_event_id "$OLD_EVENT_ID" '.event_id == $old_event_id' "$TASK_RESP" >/dev/null

# When
curl -sS -o "$ASSIGN_RESP" -w '%{http_code}' -X POST "$BASE_URL/tasks/$TASK_ID/assign" -H 'Content-Type: application/json' --data '{"event_id":'"$NEW_EVENT_ID"'}' > "$STATUS_FILE"

# Then
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "200" ]
jq -e --argjson new_event_id "$NEW_EVENT_ID" '.event_id == $new_event_id and (.updated_at | type == "string")' "$ASSIGN_RESP" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:assign_task_reassignment"

# Cleanup
:

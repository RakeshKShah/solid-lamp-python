#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENT_RESP="/tmp/assign_task_response_structure_event_${CASE_SUFFIX}.json"
TASK_RESP="/tmp/assign_task_response_structure_task_${CASE_SUFFIX}.json"
ASSIGN_RESP="/tmp/assign_task_response_structure_assign_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/assign_task_response_structure_status_${CASE_SUFFIX}.txt"
TASK_ID=""
EVENT_ID=""
cleanup_files() {
  rm -f "$EVENT_RESP" "$TASK_RESP" "$ASSIGN_RESP" "$STATUS_FILE"
}
cleanup_resources() {
  if [ -n "$TASK_ID" ]; then
    curl -sS -X DELETE "$BASE_URL/api/tasks/$TASK_ID" >/dev/null || true
  fi
  if [ -n "$EVENT_ID" ]; then
    curl -sS -X DELETE "$BASE_URL/api/events/$EVENT_ID" >/dev/null || true
  fi
}
trap 'cleanup_resources; cleanup_files' EXIT

# Given
CREATE_EVENT_STATUS="$(curl -sS -o "$EVENT_RESP" -w '%{http_code}' -X POST "$BASE_URL/api/events" -H 'Content-Type: application/json' --data '{"name":"Response structure event '"$CASE_SUFFIX"'","description":"Event for serialization","location":"Room E"}')"
[ "$CREATE_EVENT_STATUS" = "201" ]
EVENT_ID="$(jq -r '.id' "$EVENT_RESP")"
[ "$EVENT_ID" != "null" ]

CREATE_TASK_STATUS="$(curl -sS -o "$TASK_RESP" -w '%{http_code}' -X POST "$BASE_URL/api/tasks" -H 'Content-Type: application/json' --data '{"title":"Review proposal '"$CASE_SUFFIX"'","description":"Annual budget review","status":"pending"}')"
[ "$CREATE_TASK_STATUS" = "201" ]
TASK_ID="$(jq -r '.id' "$TASK_RESP")"
[ "$TASK_ID" != "null" ]

# When
curl -sS -o "$ASSIGN_RESP" -w '%{http_code}' -X POST "$BASE_URL/api/tasks/$TASK_ID/assign" -H 'Content-Type: application/json' --data '{"event_id":'"$EVENT_ID"'}' > "$STATUS_FILE"

# Then
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "200" ]
jq -e --arg title "Review proposal $CASE_SUFFIX" --arg desc "Annual budget review" --arg status "pending" --argjson event_id "$EVENT_ID" '(.id | type == "number") and .title == $title and .description == $desc and .status == $status and .event_id == $event_id and (.created_at | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T")) and (.updated_at | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T"))' "$ASSIGN_RESP" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:assign_task_response_structure"

# Cleanup
:

#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
DATABASE_URL="${DATABASE_URL:-postgresql://app:app@toxiproxy:5432/appdb}"
CASE_SUFFIX="$(date +%s)-$$"
EVENT_NAME="Team Alpha ${CASE_SUFFIX}"
TASK_TITLE="Team Alpha deliverable ${CASE_SUFFIX}"
RESPONSE_FILE="/tmp/create_task_with_ownership_details_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/create_task_with_ownership_details_${CASE_SUFFIX}.status"
TASK_ID=""
EVENT_ID=""
cleanup_files() { rm -f "$RESPONSE_FILE" "$STATUS_FILE"; }
cleanup_db() {
  if [ -n "${TASK_ID}" ]; then
    psql "$DATABASE_URL" -c "DELETE FROM tasks WHERE id = ${TASK_ID};" >/dev/null
  else
    psql "$DATABASE_URL" -c "DELETE FROM tasks WHERE title = '${TASK_TITLE}';" >/dev/null
  fi
  if [ -n "${EVENT_ID}" ]; then
    psql "$DATABASE_URL" -c "DELETE FROM events WHERE id = ${EVENT_ID};" >/dev/null
  else
    psql "$DATABASE_URL" -c "DELETE FROM events WHERE name = '${EVENT_NAME}';" >/dev/null
  fi
}
trap 'cleanup_db; cleanup_files' EXIT

# Given
EVENT_ID="$(psql "$DATABASE_URL" -t -A -c "INSERT INTO events (name, description, location) VALUES ('${EVENT_NAME}', 'ownership details test event', 'CodeValid') RETURNING id;")"

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/tasks" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${TASK_TITLE}\",\"event_id\":${EVENT_ID}}" > "$STATUS_FILE"

# Then
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "201" ]
TASK_ID="$(jq -r '.id' "$RESPONSE_FILE")"
TITLE="$(jq -r '.title' "$RESPONSE_FILE")"
RESP_EVENT_ID="$(jq -r '.event_id' "$RESPONSE_FILE")"
[ "$TASK_ID" != "null" ]
[ "$TITLE" = "$TASK_TITLE" ]
[ "$RESP_EVENT_ID" = "$EVENT_ID" ]

echo "CODEVALID_TEST_ASSERTION_OK:create_task_with_ownership_details"

# Cleanup
psql "$DATABASE_URL" -c "DELETE FROM tasks WHERE id = ${TASK_ID};" >/dev/null
TASK_ID=""
psql "$DATABASE_URL" -c "DELETE FROM events WHERE id = ${EVENT_ID};" >/dev/null
EVENT_ID=""

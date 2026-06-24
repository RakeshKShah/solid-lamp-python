#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
DATABASE_URL="${DATABASE_URL:-postgresql://app:app@toxiproxy:5432/appdb}"
CASE_SUFFIX="$(date +%s)-$$"
TASK_TITLE="Update documentation ${CASE_SUFFIX}"
RESPONSE_FILE="/tmp/create_task_with_all_optional_fields_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/create_task_with_all_optional_fields_${CASE_SUFFIX}.status"
TASK_ID=""
cleanup_files() { rm -f "$RESPONSE_FILE" "$STATUS_FILE"; }
cleanup_db() {
  if [ -n "${TASK_ID}" ]; then
    psql "$DATABASE_URL" -c "DELETE FROM tasks WHERE id = ${TASK_ID};" >/dev/null
  else
    psql "$DATABASE_URL" -c "DELETE FROM tasks WHERE title = '${TASK_TITLE}';" >/dev/null
  fi
}
trap 'cleanup_db; cleanup_files' EXIT

# Given
: "No setup required"

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/tasks" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${TASK_TITLE}\",\"description\":\"Revise API docs for v2.0 release\",\"status\":\"in_progress\"}" > "$STATUS_FILE"

# Then
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "201" ]
TASK_ID="$(jq -r '.id' "$RESPONSE_FILE")"
TITLE="$(jq -r '.title' "$RESPONSE_FILE")"
DESCRIPTION="$(jq -r '.description' "$RESPONSE_FILE")"
TASK_STATUS="$(jq -r '.status' "$RESPONSE_FILE")"
EVENT_ID="$(jq -r '.event_id' "$RESPONSE_FILE")"
[ "$TASK_ID" != "null" ]
[ "$TITLE" = "$TASK_TITLE" ]
[ "$DESCRIPTION" = "Revise API docs for v2.0 release" ]
[ "$TASK_STATUS" = "in_progress" ]
[ "$EVENT_ID" = "null" ]

echo "CODEVALID_TEST_ASSERTION_OK:create_task_with_all_optional_fields"

# Cleanup
psql "$DATABASE_URL" -c "DELETE FROM tasks WHERE id = ${TASK_ID};" >/dev/null
TASK_ID=""

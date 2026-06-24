#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
DATABASE_URL="${DATABASE_URL:-postgresql://app:app@toxiproxy:5432/appdb}"
CASE_SUFFIX="$(date +%s)-$$"
TASK_TITLE="Review pull request #42 ${CASE_SUFFIX}"
RESPONSE_FILE="/tmp/create_task_minimal_title_only_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/create_task_minimal_title_only_${CASE_SUFFIX}.status"
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
: "No pre-existing data required"

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/tasks" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${TASK_TITLE}\"}" > "$STATUS_FILE"

# Then
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "201" ]
TASK_ID="$(jq -r '.id' "$RESPONSE_FILE")"
TITLE="$(jq -r '.title' "$RESPONSE_FILE")"
DESCRIPTION="$(jq -r '.description' "$RESPONSE_FILE")"
TASK_STATUS="$(jq -r '.status' "$RESPONSE_FILE")"
EVENT_ID="$(jq -r '.event_id' "$RESPONSE_FILE")"
CREATED_AT="$(jq -r '.created_at' "$RESPONSE_FILE")"
UPDATED_AT="$(jq -r '.updated_at' "$RESPONSE_FILE")"
[ "$TASK_ID" != "null" ]
[ -n "$TASK_ID" ]
[ "$TITLE" = "$TASK_TITLE" ]
[ "$DESCRIPTION" = "null" ]
[ "$TASK_STATUS" = "pending" ]
[ "$EVENT_ID" = "null" ]
[ "$CREATED_AT" != "null" ]
[ "$UPDATED_AT" != "null" ]

echo "CODEVALID_TEST_ASSERTION_OK:create_task_minimal_title_only"

# Cleanup
psql "$DATABASE_URL" -c "DELETE FROM tasks WHERE id = ${TASK_ID};" >/dev/null
TASK_ID=""

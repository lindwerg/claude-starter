#!/bin/bash
###############################################################################
# EVENT SYSTEM
# File-based event system for hat coordination
###############################################################################

EVENTS_DIR="${RALPH_DIR:-.bmad}/events"
EVENTS_LOG="$EVENTS_DIR/events.jsonl"

# Initialize events directory
init_events() {
    mkdir -p "$EVENTS_DIR"
    touch "$EVENTS_LOG"
}

# Emit an event
# Usage: emit_event "task_complete" '{"task_id":"TASK-001"}'
emit_event() {
    local event_type="$1"
    local payload="$2"
    local timestamp=$(date -Iseconds)

    local event="{\"type\":\"$event_type\",\"timestamp\":\"$timestamp\",\"payload\":$payload}"

    echo "$event" >> "$EVENTS_LOG"

    # Also write to individual event file for easy watching
    echo "$event" > "$EVENTS_DIR/latest_$event_type.json"

    # Log
    echo "[event] $event_type: $payload"
}

# Get latest event of type
# Usage: get_latest_event "task_complete"
get_latest_event() {
    local event_type="$1"
    local event_file="$EVENTS_DIR/latest_$event_type.json"

    if [ -f "$event_file" ]; then
        cat "$event_file"
    else
        echo "{}"
    fi
}

# Wait for event
# Usage: wait_for_event "review_complete" 300  # Wait up to 300 seconds
wait_for_event() {
    local event_type="$1"
    local timeout="${2:-60}"
    local event_file="$EVENTS_DIR/latest_$event_type.json"

    local start_time=$(date +%s)
    local initial_content=""

    if [ -f "$event_file" ]; then
        initial_content=$(cat "$event_file")
    fi

    while true; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))

        if [ $elapsed -ge $timeout ]; then
            echo "[event] Timeout waiting for $event_type"
            return 1
        fi

        if [ -f "$event_file" ]; then
            local current_content=$(cat "$event_file")
            if [ "$current_content" != "$initial_content" ]; then
                echo "$current_content"
                return 0
            fi
        fi

        sleep 1
    done
}

# Get all events since timestamp
# Usage: get_events_since "2026-01-18T10:00:00"
get_events_since() {
    local since="$1"

    if [ ! -f "$EVENTS_LOG" ]; then
        echo "[]"
        return
    fi

    # Filter events by timestamp
    jq -s "[.[] | select(.timestamp >= \"$since\")]" "$EVENTS_LOG"
}

# Clear old events (keep last N)
# Usage: cleanup_events 100
cleanup_events() {
    local keep="${1:-100}"

    if [ ! -f "$EVENTS_LOG" ]; then
        return
    fi

    local temp_file=$(mktemp)
    tail -n "$keep" "$EVENTS_LOG" > "$temp_file"
    mv "$temp_file" "$EVENTS_LOG"
}

# Event types reference
#
# TASK LIFECYCLE:
#   task_started      - Task execution began
#   task_complete     - Task finished successfully
#   task_failed       - Task failed
#   task_blocked      - Task blocked, needs human
#   task_retry        - Task being retried
#
# HAT TRANSITIONS:
#   hat_activated     - Hat took over
#   hat_complete      - Hat finished work
#   hat_handoff       - Hat passing to another hat
#
# QUALITY:
#   gates_passed      - All quality gates passed
#   gates_failed      - Quality gate(s) failed
#   tests_passing     - All tests green
#   tests_failing     - Test(s) failing
#
# REVIEW:
#   needs_review      - Code ready for review
#   review_approved   - Review passed
#   review_rejected   - Review found issues
#
# SPRINT:
#   sprint_started    - Sprint execution began
#   sprint_complete   - All tasks done
#   sprint_blocked    - Sprint blocked

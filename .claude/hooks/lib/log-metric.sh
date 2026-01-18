#!/bin/bash
###############################################################################
# Hook Metrics Logger (Bash Helper)
#
# Usage:
#   log_metric "hook-name" "PreToolUse" "$DURATION_MS" "block" "$TOOL_NAME" "$FILE_PATH"
###############################################################################

log_metric() {
    local hook_name="$1"
    local event_type="$2"
    local duration_ms="$3"
    local result="$4"
    local tool_name="${5:-}"
    local file_path="${6:-}"
    local error="${7:-}"

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    local metrics_dir="$CLAUDE_PROJECT_DIR/.claude/hooks/metrics"
    local date=$(date +"%Y-%m-%d")
    local log_file="$metrics_dir/$date.jsonl"

    # Create metrics directory if doesn't exist
    mkdir -p "$metrics_dir" 2>/dev/null || true

    # Build JSON entry
    local json="{\"timestamp\":\"$timestamp\",\"hook_name\":\"$hook_name\",\"event_type\":\"$event_type\",\"duration_ms\":$duration_ms,\"result\":\"$result\""

    if [ -n "$tool_name" ]; then
        json="$json,\"tool_name\":\"$tool_name\""
    fi

    if [ -n "$file_path" ]; then
        # Escape quotes in file path
        local escaped_path=$(echo "$file_path" | sed 's/"/\\"/g')
        json="$json,\"file_path\":\"$escaped_path\""
    fi

    if [ -n "$error" ]; then
        # Escape quotes and newlines in error
        local escaped_error=$(echo "$error" | sed 's/"/\\"/g' | tr '\n' ' ')
        json="$json,\"error\":\"$escaped_error\""
    fi

    json="$json}"

    # Append to log file (fail silently if can't write)
    echo "$json" >> "$log_file" 2>/dev/null || true
}

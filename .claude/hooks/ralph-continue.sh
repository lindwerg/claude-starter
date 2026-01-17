#!/bin/bash
# Ralph Loop Auto-Continue Hook (Stop)
# Intercepts stop and continues if tasks remain
set -e

# Read input from Claude
input=$(cat)

# Check for explicit completion markers - let these through
if echo "$input" | grep -qE "(PROJECT_COMPLETE|BLOCKED|LIMIT_REACHED|SPRINT_COMPLETE)"; then
  echo '{"result": "continue"}'
  exit 0
fi

# Check if we're in a Ralph Loop session (task-queue exists)
if [[ ! -f ".bmad/task-queue.yaml" ]]; then
  echo '{"result": "continue"}'
  exit 0
fi

# Count pending tasks
pending_count=$(yq '.tasks[] | select(.status == "pending")' .bmad/task-queue.yaml 2>/dev/null | grep -c "id:" || echo "0")

if [[ "$pending_count" -gt 0 ]]; then
  # Tasks remain - signal to continue
  echo '{"result": "continue", "message": "Ralph Loop: '"$pending_count"' tasks remaining. Continue with next task from .bmad/task-queue.yaml"}'
  exit 0
fi

# All tasks done
echo '{"result": "continue"}'

#!/bin/bash
# Sprint Plan Post-Validator Hook (PostToolUse)
# Reminds to create task-queue.yaml after sprint-status.yaml is written
set -e

# Read input from Claude
input=$(cat)

# Parse tool info
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# Only trigger after Write to sprint-status.yaml (last step of sprint-planning)
if [[ "$tool_name" != "Write" ]] || [[ ! "$file_path" =~ sprint-status\.yaml$ ]]; then
  echo '{"result": "continue"}'
  exit 0
fi

# Check if task-queue.yaml exists
if [[ ! -f ".bmad/task-queue.yaml" ]]; then
  cat << 'EOF'
{
  "result": "continue",
  "message": "⚠️ CRITICAL: .bmad/task-queue.yaml NOT CREATED!\n\nRalph Loop CANNOT work without task-queue.yaml.\n\nYou MUST now execute Part 10.5: Generate Task Queue\n\n1. For each story in Sprint 1, create atomic tasks (30-60 min each)\n2. Format: TASK-{story_num}-{letter} (e.g., TASK-001-A)\n3. Include: type, estimated_minutes, depends_on, outputs, acceptance\n4. Save to .bmad/task-queue.yaml\n\nDO NOT finish sprint-planning without creating task-queue.yaml!"
}
EOF
  exit 0
fi

# Task queue exists - all good
echo '{"result": "continue", "message": "✅ task-queue.yaml exists. Sprint planning complete!"}'

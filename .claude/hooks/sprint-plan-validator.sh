#!/bin/bash
# Sprint Plan Validator Hook (PreToolUse)
# Blocks infrastructure stories if architecture already exists
set -e

# Read input from Claude
input=$(cat)

# Parse tool info
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
content=$(echo "$input" | jq -r '.tool_input.content // empty')

# Only check Write operations to sprint-plan files
if [[ "$tool_name" != "Write" ]] || [[ ! "$file_path" =~ sprint-plan.*\.md$ ]]; then
  echo '{"result": "continue"}'
  exit 0
fi

# Check if architecture exists (created by /architecture workflow)
arch_exists=false
if [[ -d "backend/src" ]] && [[ -d "frontend/src" ]] && [[ -f "backend/prisma/schema.prisma" ]]; then
  arch_exists=true
fi

# If architecture exists, block infrastructure stories
if [[ "$arch_exists" == "true" ]]; then
  # Check for INF-* patterns or infrastructure-related content
  if echo "$content" | grep -qiE "(INF-[0-9]+|### Infrastructure Stories|STORY-INF-|Настройка monorepo|Настройка PostgreSQL|Настройка Redis|Настройка CI/CD|Database Schema.*Setup|Backend Skeleton|Frontend Setup|Docker Setup)"; then
    cat << 'EOF'
{
  "result": "block",
  "message": "⚠️ BLOCKED: Architecture skeleton already exists!\n\n/architecture already created:\n- backend/src/ (VSA skeleton)\n- frontend/src/ (FSD skeleton)\n- prisma/schema.prisma\n- docker-compose.yml\n- CI/CD, ESLint, Prettier\n\n❌ FORBIDDEN: INF-*, 'Infrastructure Stories', 'Database Schema Setup', 'Project Setup'\n\n✅ REQUIRED: First story MUST be a BUSINESS FEATURE:\n- TMA Authentication\n- Data Pipeline Integration\n- User Registration API\n\nPlease recreate sprint plan WITHOUT infrastructure stories."
}
EOF
    exit 0
  fi
fi

echo '{"result": "continue"}'

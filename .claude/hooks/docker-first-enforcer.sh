#!/bin/bash
###############################################################################
# DOCKER-FIRST ENFORCER HOOK (PreToolUse Write)
#
# Blocks task-queue.yaml creation if mentioned services are NOT in docker-compose.yml.
#
# Problem: Tasks mention external services (ComfyUI, Redis, PostgreSQL)
#          but developer must install manually → dependency hell
#
# Solution: Enforce Docker-first approach - ALL dependencies in docker-compose.yml
#
# Trigger: PreToolUse Write на task-queue.yaml
#
# Example:
# ❌ task-queue mentions "ComfyUI" → docker-compose.yml NO "comfyui:" service
# ✅ task-queue mentions "ComfyUI" → docker-compose.yml HAS "comfyui:" service
###############################################################################

set -e

INPUT=$(cat)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Get file path from input JSON
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null)

# Only check task queue files
if [[ "$FILE_PATH" != *"task-queue.yaml"* ]]; then
  echo '{"result":"continue"}'
  exit 0
fi

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
  echo '{"result":"continue"}'  # First sprint, no docker yet - will be checked by infrastructure-readiness-detector
  exit 0
fi

# Only check if file exists (PreToolUse on Write sees file BEFORE write)
if [ ! -f "$FILE_PATH" ]; then
  echo '{"result":"continue"}'
  exit 0
fi

# === DOCKER-FIRST ENFORCEMENT ===

# Extract services mentioned in task acceptance criteria
MENTIONED_SERVICES=$(grep -oiE "(ComfyUI|postgres|postgresql|redis|rabbitmq|minio|elasticsearch|kafka|airflow|mlflow)" "$FILE_PATH" | sort -u || true)

if [ -n "$MENTIONED_SERVICES" ]; then
  MISSING_SERVICES=()

  # Check each service is in docker-compose.yml
  for service in $MENTIONED_SERVICES; do
    # Normalize service name to lowercase
    service_lower=$(echo "$service" | tr '[:upper:]' '[:lower:]')

    # Handle PostgreSQL alias
    if [ "$service_lower" = "postgresql" ]; then
      service_lower="postgres"
    fi

    # Check if service exists in docker-compose.yml
    if ! grep -qiE "^\s+$service_lower:" docker-compose.yml; then
      MISSING_SERVICES+=("$service_lower")
    fi
  done

  # If any services missing, BLOCK
  if [ ${#MISSING_SERVICES[@]} -gt 0 ]; then
    MISSING_LIST=$(printf '  - %s\n' "${MISSING_SERVICES[@]}")

    cat << EOF
{"result":"block","message":"⚠️ DOCKER-FIRST VIOLATION\n\nTask queue mentions services:\n$MISSING_LIST\n\nBut they are NOT in docker-compose.yml.\n\n✅ REQUIRED ACTION:\nAdd services to docker-compose.yml:\n\nservices:\n  ${MISSING_SERVICES[0]}:\n    image: appropriate/image:latest\n    ports:\n      - \"PORT:PORT\"\n    environment:\n      - KEY=value\n    volumes:\n      - ./data:/data\n\n📝 RULE:\n- ALL external dependencies MUST be in Docker\n- No manual installation allowed\n- Project MUST be runnable via 'docker-compose up'\n\n🚫 FORBIDDEN:\n- Manual service installation\n- 'Install X on your machine' instructions\n- localhost:PORT without Docker\n\n✅ CORRECT:\n- docker-compose up -d  # Everything works\n- All services containerized\n- Reproducible environment"}
EOF
    exit 0
  fi
fi

# All checks passed - continue
echo '{"result":"continue"}'

#!/bin/bash
###############################################################################
# LOCAL TESTABILITY ENFORCER HOOK (PostToolUse Write)
#
# Validates and tests docker-compose.yml after ANY modification.
#
# Problem: docker-compose.yml changed → unknown if project still runnable
#          → Manual testing required → Time wasted
#
# Solution: AUTOMATICALLY verify project is runnable after EVERY change
#
# Trigger: PostToolUse Write на docker-compose.yml
#
# Steps:
# 1. Validate docker-compose syntax
# 2. Start services (docker-compose up -d)
# 3. Wait for startup (10s)
# 4. Check all services UP
# 5. Check health endpoints (PostgreSQL, Redis, etc.)
#
# Example:
# ❌ docker-compose.yml updated → syntax error → BLOCK (fix before continuing)
# ✅ docker-compose.yml updated → all services UP → continue
###############################################################################

set -e

INPUT=$(cat)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Get file path from input JSON
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null)

# Only trigger on docker-compose.yml changes
if [[ "$FILE_PATH" != *"docker-compose.yml"* ]] && [[ "$FILE_PATH" != *"docker-compose.yaml"* ]]; then
  echo '{"result":"continue"}'
  exit 0
fi

echo "🧪 Testing docker-compose.yml..." >&2

# === VALIDATION ===

# 1. Validate docker-compose syntax
if ! docker-compose config > /dev/null 2>&1; then
  cat << 'EOF'
{"result":"block","message":"⚠️ DOCKER-COMPOSE INVALID\n\ndocker-compose.yml has syntax errors.\n\n✅ FIX SYNTAX FIRST:\ndocker-compose config\n\nCommon issues:\n- Indentation (must be 2 spaces)\n- Missing quotes around special characters\n- Invalid YAML syntax"}
EOF
  exit 0
fi

echo "✅ docker-compose.yml syntax valid" >&2

# 2. Start services
echo "🚀 Starting Docker services..." >&2
docker-compose up -d 2>&1 | head -20 >&2

# 3. Wait for startup
echo "⏳ Waiting 10 seconds for services to start..." >&2
sleep 10

# 4. Check all services are UP
FAILED_SERVICES=$(docker-compose ps --services --filter "status=running" 2>/dev/null | comm -13 - <(docker-compose ps --services) || true)

if [ -n "$FAILED_SERVICES" ]; then
  FAILED_LIST=$(echo "$FAILED_SERVICES" | sed 's/^/  - /')

  cat << EOF
{"result":"block","message":"⚠️ DOCKER SERVICES FAILED TO START\n\nFailed services:\n$FAILED_LIST\n\n✅ CHECK LOGS:\ndocker-compose logs $FAILED_SERVICES\n\nCommon issues:\n- Port already in use (check: lsof -i :PORT)\n- Missing environment variables\n- Invalid image name or tag\n- Volume mount path doesn't exist"}
EOF
  exit 0
fi

echo "✅ All services running" >&2

# 5. Health checks (if services present)
HEALTH_CHECKS=()

# PostgreSQL health check
if docker-compose ps --services | grep -q "postgres"; then
  echo "🔍 Checking PostgreSQL health..." >&2
  if ! docker-compose exec -T postgres pg_isready > /dev/null 2>&1; then
    HEALTH_CHECKS+=("PostgreSQL not ready (wait 30s or check logs)")
  else
    echo "✅ PostgreSQL healthy" >&2
  fi
fi

# Redis health check
if docker-compose ps --services | grep -q "redis"; then
  echo "🔍 Checking Redis health..." >&2
  if ! docker-compose exec -T redis redis-cli ping 2>/dev/null | grep -q "PONG"; then
    HEALTH_CHECKS+=("Redis not responding")
  else
    echo "✅ Redis healthy" >&2
  fi
fi

# ComfyUI health check
if docker-compose ps --services | grep -qiE "(comfyui|comfy)"; then
  echo "🔍 Checking ComfyUI health..." >&2
  sleep 5  # ComfyUI needs more time
  if ! curl -s http://localhost:8188 > /dev/null 2>&1; then
    HEALTH_CHECKS+=("ComfyUI not responding at http://localhost:8188 (may need more startup time)")
  else
    echo "✅ ComfyUI responding" >&2
  fi
fi

# If any health checks failed, BLOCK
if [ ${#HEALTH_CHECKS[@]} -gt 0 ]; then
  FAILED_LIST=$(printf '\n  - %s' "${HEALTH_CHECKS[@]}")

  cat << EOF
{"result":"block","message":"⚠️ HEALTH CHECKS FAILED\n\nServices started but not healthy:\n$FAILED_LIST\n\n✅ TROUBLESHOOT:\n1. Wait 30 seconds and check again:\n   docker-compose ps\n\n2. Check service logs:\n   docker-compose logs <service-name>\n\n3. Restart services:\n   docker-compose restart\n\n📝 TIP:\nSome services (ComfyUI, ML models) need 30-60s startup time."}
EOF
  exit 0
fi

# All checks passed
echo "✅ Docker services UP and healthy" >&2
echo '{"result":"continue","message":"✅ Docker services verified: project is runnable locally"}'

#!/bin/bash
###############################################################################
# READINESS VERIFICATION GATE HOOK (PreToolUse Task)
#
# Blocks Ralph Loop if infrastructure is NOT ready.
#
# Problem: Ralph Loop starts, but external dependencies not running
#          → Worker crashes, tests fail, time wasted
#
# Solution: VERIFY infrastructure readiness BEFORE executing tasks
#
# Trigger: PreToolUse Task (specifically ralph-loop)
#
# Checks:
# 1. Docker services UP
# 2. Python dependencies installed (if workers/)
# 3. Models directory exists (if ML project)
# 4. External services responding (health checks)
#
# Example:
# ❌ Ralph Loop starts → ComfyUI not running → Worker crashes
# ✅ Hook blocks → User starts ComfyUI → Ralph Loop continues
###############################################################################

set -e

INPUT=$(cat)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Get tool name from input JSON
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)

# Only intercept Task tool calls
if [[ "$TOOL_NAME" != "Task" ]]; then
  echo '{"result":"continue"}'
  exit 0
fi

# Only intercept ralph-loop specifically
if ! echo "$INPUT" | grep -q "ralph-loop"; then
  echo '{"result":"continue"}'
  exit 0
fi

# Check if Ralph Loop already running (marker exists)
if [ -f ".bmad/ralph-in-progress" ]; then
  echo '{"result":"continue"}'  # Already verified
  exit 0
fi

# === READINESS VERIFICATION ===

FAILED_CHECKS=()

# 1. Check docker-compose services are UP
if [ -f "docker-compose.yml" ]; then
  # Get list of services defined
  REQUIRED_SERVICES=$(docker-compose config --services 2>/dev/null || true)

  if [ -n "$REQUIRED_SERVICES" ]; then
    for service in $REQUIRED_SERVICES; do
      # Check if service is running
      if ! docker-compose ps | grep "$service" | grep -q "Up"; then
        FAILED_CHECKS+=("Docker service '$service' not running (start: docker-compose up -d)")
      fi
    done
  fi
fi

# 2. Check Python worker dependencies (if workers/ exists)
if [ -d "workers" ] && [ -f "workers/requirements.txt" ]; then
  # Check if critical packages installed
  if ! pip3 list | grep -qF "bullmq"; then
    FAILED_CHECKS+=("Python worker dependencies not installed (cd workers && pip install -r requirements.txt)")
  fi
fi

# 3. Check models directory if ML project (GENERIC check)
if [ -f ".bmad/task-queue.yaml" ]; then
  if grep -qiE "(FLUX|Stable\s+Diffusion|Whisper|LLaMA|model)" .bmad/task-queue.yaml; then
    if [ ! -d "models" ]; then
      FAILED_CHECKS+=("models/ directory missing (create: mkdir models && download required models)")
    else
      # Check if models directory is empty
      if [ -z "$(ls -A models 2>/dev/null)" ]; then
        FAILED_CHECKS+=("models/ directory is empty (download required models - see project README)")
      fi
    fi
  fi
fi

# 4. Check ComfyUI if mentioned (health check)
if [ -f ".bmad/task-queue.yaml" ] && grep -qiE "ComfyUI" .bmad/task-queue.yaml; then
  if ! curl -s http://localhost:8188/system_stats > /dev/null 2>&1 && \
     ! curl -s http://localhost:8188 > /dev/null 2>&1; then
    FAILED_CHECKS+=("ComfyUI not responding at http://localhost:8188 (start: docker-compose up -d comfyui)")
  fi
fi

# 5. Check PostgreSQL if mentioned
if [ -f ".bmad/task-queue.yaml" ] && grep -qiE "(PostgreSQL|postgres)" .bmad/task-queue.yaml; then
  if docker-compose ps | grep -q "postgres"; then
    if ! docker-compose exec -T postgres pg_isready > /dev/null 2>&1; then
      FAILED_CHECKS+=("PostgreSQL not ready (wait or check: docker-compose logs postgres)")
    fi
  fi
fi

# 6. Check Redis if mentioned
if [ -f ".bmad/task-queue.yaml" ] && grep -qiE "redis" .bmad/task-queue.yaml; then
  if docker-compose ps | grep -q "redis"; then
    if ! docker-compose exec -T redis redis-cli ping 2>/dev/null | grep -q "PONG"; then
      FAILED_CHECKS+=("Redis not responding (check: docker-compose logs redis)")
    fi
  fi
fi

# If any checks failed, BLOCK
if [ ${#FAILED_CHECKS[@]} -gt 0 ]; then
  FAILED_LIST=$(printf '\n  - %s' "${FAILED_CHECKS[@]}")

  cat << EOF
{"result":"block","message":"⚠️ INFRASTRUCTURE NOT READY\n\nCannot start Ralph Loop. Failed readiness checks:\n$FAILED_LIST\n\n✅ FIX THESE FIRST:\n\n1. Start Docker services:\n   docker-compose up -d\n\n2. Install Python dependencies (if workers/):\n   cd workers && pip install -r requirements.txt\n\n3. Download models (if ML project):\n   mkdir -p models\n   # See project README for model download instructions\n\n4. Verify services:\n   docker-compose ps  # All services should be 'Up'\n   curl http://localhost:8188  # ComfyUI responds (if applicable)\n\n📝 RULE:\nInfrastructure MUST be ready BEFORE code execution.\nNo exceptions.\n\n🎯 GOAL:\n'docker-compose up -d' should make project fully runnable.\nNothing manual allowed."}
EOF
  exit 0
fi

# All checks passed - continue
echo '{"result":"continue"}'

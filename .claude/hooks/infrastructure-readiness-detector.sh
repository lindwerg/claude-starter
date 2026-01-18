#!/bin/bash
###############################################################################
# INFRASTRUCTURE READINESS DETECTOR HOOK (PreToolUse Write)
#
# Blocks sprint-planning if acceptance criteria mention infrastructure dependencies
# but no corresponding preparatory tasks exist.
#
# Problem: Sprint-planning creates tasks for CODE (backend/frontend/test)
#          but IGNORES infrastructure requirements (ComfyUI, FLUX, ffmpeg, etc.)
#
# Solution: Detect GENERIC infrastructure patterns and BLOCK if no prep tasks.
#
# Trigger: PreToolUse Write на sprint-plan-*.md
#
# Example:
# ❌ Acceptance: "Generate images via ComfyUI" → NO "Install ComfyUI" task
# ✅ Acceptance: "Generate images via ComfyUI" → Story includes "Setup ComfyUI Docker"
###############################################################################

set -e

INPUT=$(cat)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Get file path from input JSON
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null)

# Only check sprint plan files
if [[ "$FILE_PATH" != *"sprint-plan"* ]] && [[ "$FILE_PATH" != *"docs/"*".md" ]]; then
  echo '{"result":"continue"}'
  exit 0
fi

# Only check if file exists (PreToolUse on Write sees file BEFORE write)
# For new files, we can't grep content, so skip
if [ ! -f "$FILE_PATH" ]; then
  echo '{"result":"continue"}'
  exit 0
fi

# === INFRASTRUCTURE DEPENDENCY DETECTION ===

DETECTED_DEPS=()
DETECTED_SERVICES=""

# Check for external services (Docker/API)
if grep -qiE "(ComfyUI|Airflow|MLflow|Kafka|Elasticsearch|RabbitMQ|MinIO|Jupyter)" "$FILE_PATH"; then
  DETECTED_DEPS+=("EXTERNAL_SERVICES")
  DETECTED_SERVICES=$(grep -oiE "(ComfyUI|Airflow|MLflow|Kafka|Elasticsearch|RabbitMQ|MinIO|Jupyter)" "$FILE_PATH" | sort -u | tr '\n' ', ')
fi

# Check for ML models (large downloads)
if grep -qiE "(FLUX|Stable\s+Diffusion|Whisper|LLaMA|BERT|GPT|LoRA|YOLO)" "$FILE_PATH"; then
  DETECTED_DEPS+=("ML_MODELS")
  MODELS=$(grep -oiE "(FLUX|Stable\s+Diffusion|Whisper|LLaMA|BERT|GPT|LoRA|YOLO)" "$FILE_PATH" | sort -u | tr '\n' ', ')
  DETECTED_SERVICES="${DETECTED_SERVICES}${MODELS}"
fi

# Check for CLI tools (system dependencies)
if grep -qiE "(ffmpeg|imagemagick|wkhtmltopdf|pandoc|tesseract|opencv)" "$FILE_PATH"; then
  DETECTED_DEPS+=("CLI_TOOLS")
  CLI=$(grep -oiE "(ffmpeg|imagemagick|wkhtmltopdf|pandoc|tesseract|opencv)" "$FILE_PATH" | sort -u | tr '\n' ', ')
  DETECTED_SERVICES="${DETECTED_SERVICES}${CLI}"
fi

# Check for cloud resources (provisioning)
if grep -qiE "(S3\s+bucket|GCS\s+bucket|CloudFront|Lambda|Cloud\s+Function)" "$FILE_PATH"; then
  DETECTED_DEPS+=("CLOUD_RESOURCES")
  CLOUD=$(grep -oiE "(S3\s+bucket|GCS\s+bucket|CloudFront|Lambda|Cloud\s+Function)" "$FILE_PATH" | sort -u | tr '\n' ', ')
  DETECTED_SERVICES="${DETECTED_SERVICES}${CLOUD}"
fi

# Remove trailing comma
DETECTED_SERVICES=$(echo "$DETECTED_SERVICES" | sed 's/,$//')

# If ANY dependencies detected, check for preparatory tasks
if [ ${#DETECTED_DEPS[@]} -gt 0 ]; then

  # Check for preparatory stories/tasks
  # Keywords: setup, install, configure, deploy, provision, download
  if ! grep -qiE "(setup|install|configure|deploy|provision|download).*(ComfyUI|model|service|tool|infrastructure|FLUX|ffmpeg|Airflow)" "$FILE_PATH" && \
     ! grep -qiE "(infrastructure|setup|preparation|environment).*(story|task)" "$FILE_PATH" && \
     ! grep -qiE "PREP-\d+|INF-\d+|SETUP-\d+" "$FILE_PATH"; then

    cat << EOF
{"result":"block","message":"⚠️ INFRASTRUCTURE DEPENDENCY DETECTED\n\nAcceptance criteria mention external dependencies:\n  $DETECTED_SERVICES\n\nBut NO preparatory tasks found.\n\n🔍 DETECTED PATTERNS:\n- External services (ComfyUI, Airflow, MLflow, etc.)\n- ML models (FLUX, Stable Diffusion, Whisper, etc.)\n- CLI tools (ffmpeg, imagemagick, pandoc, etc.)\n- Cloud resources (S3 bucket, Lambda, CloudFront, etc.)\n\n✅ REQUIRED ACTION:\nAdd PREPARATORY stories/tasks BEFORE feature implementation.\n\n**Example Structure:**\n\nSTORY-000: Infrastructure Setup (2 pts)\n  TASK-000-A: Install ComfyUI in Docker (60min)\n  TASK-000-B: Download FLUX.1 Dev model to models/ (30min)\n  TASK-000-C: Create docker-compose.yml for ComfyUI (30min)\n  TASK-000-D: Verify ComfyUI /health endpoint (15min)\n\nSTORY-001: Your Business Feature (5 pts)\n  ...\n\n❌ WITHOUT THIS:\n- Worker cannot connect to service (not running)\n- E2E tests fail (dependency not available)\n- Local testing impossible\n- Sprint must be re-planned\n\n📝 CRITICAL:\n- Preparatory tasks MUST be FIRST in sprint\n- Use ID pattern: PREP-*, SETUP-*, or INF-*\n- EVERYTHING must be in Docker (no manual installation)"}
EOF
    exit 0
  fi
fi

# All checks passed - continue
echo '{"result":"continue"}'

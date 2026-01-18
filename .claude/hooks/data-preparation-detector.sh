#!/bin/bash
###############################################################################
# DATA PREPARATION DETECTOR HOOK (PreToolUse Write)
#
# Blocks sprint-planning if acceptance criteria mention data requirements
# but no corresponding data-preparation task exists.
#
# Problem: Sprint-planning creates tasks for CODE (backend/frontend/test)
#          but IGNORES data requirements ("40 images", "dataset", etc.)
#
# Solution: Detect patterns in acceptance criteria and BLOCK if no prep task.
#
# Trigger: PreToolUse Write на sprint-plan-*.md
#
# Example:
# ❌ Acceptance: "Train Lora model with 40 images" → NO "Prepare 40 images" task
# ✅ Acceptance: "Train Lora model" → Story includes "Prepare training dataset"
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

# Check if acceptance criteria mention data requirements
# Patterns: "N images", "N files", "N records", "dataset", "training data"
if grep -qE "\d+\s+(images|files|records|samples|examples|data\s+points)" "$FILE_PATH" || \
   grep -qiE "(dataset|training\s+data|test\s+data|sample\s+data)" "$FILE_PATH"; then

  # Check if there's a corresponding data-preparation story/task
  # Look for keywords: prepare, upload, collect, generate, create dataset
  if ! grep -qiE "(prepare|upload|collect|generate|create).*(images|files|records|dataset|data)" "$FILE_PATH" && \
     ! grep -qiE "(data.*preparation|data.*collection|data.*upload)" "$FILE_PATH"; then

    cat << 'EOF'
{"result":"block","message":"⚠️ DATA DEPENDENCY DETECTED\n\nAcceptance criteria mention data requirements (N images/files/records/dataset), but no data-preparation story found.\n\n🔍 DETECTED PATTERNS:\n- 'N images/files/records'\n- 'dataset', 'training data', etc.\n\n✅ REQUIRED ACTION:\nAdd a story or task for data preparation:\n\nExamples:\n- 'Prepare 40 training images for Lora model'\n- 'Upload user dataset to S3'\n- 'Generate synthetic test data'\n- 'Collect 1000 sample records'\n\n❌ WITHOUT THIS:\n- E2E tests will fail (data not found)\n- Implementation will be blocked\n- Sprint must be re-planned\n\n📝 TIP:\nAdd story BEFORE training/processing story:\n  STORY-001: Prepare training dataset (2 pts)\n  STORY-002: Implement Lora training (5 pts)"}
EOF
    exit 0
  fi
fi

# All checks passed - continue
echo '{"result":"continue"}'

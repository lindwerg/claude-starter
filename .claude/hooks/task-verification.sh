#!/bin/bash
###############################################################################
# TASK VERIFICATION HOOK (PostToolUse)
#
# Automatically verifies task completion after Write/Edit:
# 1. Checks if created file is in current task's outputs
# 2. Verifies all outputs exist
# 3. Runs quality gates
# 4. Updates task-queue.yaml status
#
# Only runs when Ralph Loop is active (.bmad/ralph-in-progress exists)
###############################################################################

set -e

# Get project directory
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Quick check: only run if Ralph is active
if [ ! -f "$PROJECT_DIR/.bmad/ralph-in-progress" ]; then
    echo '{"result":"continue"}'
    exit 0
fi

# Quick check: task-queue.yaml must exist
if [ ! -f "$PROJECT_DIR/.bmad/task-queue.yaml" ]; then
    echo '{"result":"continue"}'
    exit 0
fi

# Run pre-compiled handler (10x faster than npx tsx)
cd "$PROJECT_DIR/.claude/hooks"
cat | node dist/task-verification.js

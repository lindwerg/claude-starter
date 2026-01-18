#!/bin/bash
#
# Ralph Validation Cleanup Hook (PostToolUse Write)
#
# Срабатывает после записи файлов через Write tool.
# Если записан task-queue.yaml и существует маркер валидации — удаляет маркер.
#

set -e

cd "$CLAUDE_PROJECT_DIR/.claude/hooks"
cat | npx tsx src/ralph-validation-cleanup.ts

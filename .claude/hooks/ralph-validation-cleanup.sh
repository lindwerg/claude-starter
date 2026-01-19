#!/bin/bash
#
# Ralph Validation Cleanup Hook (PostToolUse Write)
#
# Срабатывает после записи файлов через Write tool.
# Если записан task-queue.yaml и существует маркер валидации — удаляет маркер.
#

set -e

# Безопасно определяем директорию проекта
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Проверяем существование .claude/hooks в проекте
if [ ! -d "$PROJECT_DIR/.claude/hooks" ]; then
    # Fallback: ищем .claude/hooks относительно pwd
    if [ -d "$(pwd)/.claude/hooks" ]; then
        PROJECT_DIR="$(pwd)"
    else
        # Если не нашли - просто пропускаем (не прерываем операцию)
        echo "Warning: .claude/hooks not found, skipping ralph-validation-cleanup" >&2
        exit 0
    fi
fi

cd "$PROJECT_DIR/.claude/hooks"
cat | node dist/ralph-validation-cleanup.cjs

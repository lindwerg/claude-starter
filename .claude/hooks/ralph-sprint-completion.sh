#!/bin/bash
#
# Ralph Sprint Completion Hook (Stop)
#
# Срабатывает при завершении Ralph Loop.
# Проверяет, все ли задачи спринта выполнены.
# Если да — архивирует спринт, создаёт маркер валидации, блокирует.
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
        echo "Warning: .claude/hooks not found, skipping ralph-sprint-completion" >&2
        exit 0
    fi
fi

cd "$PROJECT_DIR/.claude/hooks"
cat | node dist/ralph-sprint-completion.cjs

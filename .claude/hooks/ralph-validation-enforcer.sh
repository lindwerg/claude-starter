#!/bin/bash
#
# Ralph Validation Enforcer Hook (PreToolUse Task)
#
# Срабатывает перед spawn subagent (Task tool).
# Блокирует запуск Ralph если существует маркер .bmad/sprint-validation-pending.
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
        echo "Warning: .claude/hooks not found, skipping ralph-validation-enforcer" >&2
        exit 0
    fi
fi

cd "$PROJECT_DIR/.claude/hooks"
cat | node dist/ralph-validation-enforcer.cjs

#!/bin/bash
#
# Ralph Sprint Completion Hook (Stop)
#
# Срабатывает при завершении Ralph Loop.
# Проверяет, все ли задачи спринта выполнены.
# Если да — архивирует спринт, создаёт маркер валидации, блокирует.
#

set -e

cd "$CLAUDE_PROJECT_DIR/.claude/hooks"
cat | node dist/ralph-sprint-completion.js

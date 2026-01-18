#!/bin/bash
#
# Ralph Validation Enforcer Hook (PreToolUse Task)
#
# Срабатывает перед spawn subagent (Task tool).
# Блокирует запуск Ralph если существует маркер .bmad/sprint-validation-pending.
#

set -e

cd "$CLAUDE_PROJECT_DIR/.claude/hooks"
cat | npx tsx src/ralph-validation-enforcer.ts

#!/bin/bash
###
# PostToolUse Hook - Auto-commit after Edit/Write when Ralph is running
###

set -e

INPUT=$(cat)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
RALPH_MARKER="$PROJECT_DIR/.bmad/ralph-in-progress"

# Only run if Ralph is active
[ ! -f "$RALPH_MARKER" ] && echo '{"result":"continue"}' && exit 0

# Check if there are changes to commit
cd "$PROJECT_DIR"
if git diff --quiet && git diff --cached --quiet; then
    echo '{"result":"continue"}'
    exit 0
fi

# Get changed files for commit message
CHANGED=$(git diff --name-only | head -3 | tr '\n' ', ' | sed 's/,$//')

# Auto-commit
git add -A
git commit -m "feat(ralph): auto-commit changes to $CHANGED" 2>/dev/null || true

echo '{"result":"continue","message":"Auto-committed changes"}'

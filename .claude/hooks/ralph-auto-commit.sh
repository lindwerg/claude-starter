#!/bin/bash
###
# PostToolUse Hook - Auto-commit after Edit/Write when Ralph is running
# Creates descriptive commits using current task from task-queue.yaml
###

set -e

INPUT=$(cat)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
RALPH_MARKER="$PROJECT_DIR/.bmad/ralph-in-progress"
TASK_QUEUE="$PROJECT_DIR/.bmad/task-queue.yaml"

# Only run if Ralph is active
[ ! -f "$RALPH_MARKER" ] && echo '{"result":"continue"}' && exit 0

# Check if there are changes to commit
cd "$PROJECT_DIR"
if git diff --quiet && git diff --cached --quiet; then
    echo '{"result":"continue"}'
    exit 0
fi

# Try to get current task info from task-queue.yaml
COMMIT_MSG="feat(ralph): update files"

if [ -f "$TASK_QUEUE" ] && command -v yq &> /dev/null; then
    CURRENT_TASK_ID=$(yq -r '.current_task // ""' "$TASK_QUEUE" 2>/dev/null)

    if [ -n "$CURRENT_TASK_ID" ] && [ "$CURRENT_TASK_ID" != "null" ]; then
        # Get task details (yq uses // "" for defaults, not // empty)
        STORY_ID=$(yq -r ".tasks[] | select(.id == \"$CURRENT_TASK_ID\") | .story_id" "$TASK_QUEUE" 2>/dev/null)
        TASK_TITLE=$(yq -r ".tasks[] | select(.id == \"$CURRENT_TASK_ID\") | .title" "$TASK_QUEUE" 2>/dev/null)
        TASK_TYPE=$(yq -r ".tasks[] | select(.id == \"$CURRENT_TASK_ID\") | .type" "$TASK_QUEUE" 2>/dev/null)

        if [ -n "$STORY_ID" ] && [ "$STORY_ID" != "null" ] && [ -n "$TASK_TITLE" ] && [ "$TASK_TITLE" != "null" ]; then
            # Format: feat(story/type): Task title
            # Lowercase story_id prefix for conventional commits
            PREFIX=$(echo "$STORY_ID" | tr '[:upper:]' '[:lower:]' | sed 's/-[0-9]*$//')
            COMMIT_MSG="feat($PREFIX): $TASK_TITLE"

            # Add task type as scope
            if [ -n "$TASK_TYPE" ] && [ "$TASK_TYPE" != "null" ]; then
                COMMIT_MSG="feat($PREFIX/$TASK_TYPE): $TASK_TITLE"
            fi
        fi
    fi
fi

# Fallback: use changed files if no task info
if [ "$COMMIT_MSG" = "feat(ralph): update files" ]; then
    CHANGED=$(git diff --name-only | head -3 | tr '\n' ', ' | sed 's/,$//')
    if [ -n "$CHANGED" ]; then
        COMMIT_MSG="feat(ralph): update $CHANGED"
    fi
fi

# Auto-commit
git add -A
git commit -m "$COMMIT_MSG" 2>/dev/null || true

echo '{"result":"continue","message":"Auto-committed: '"${COMMIT_MSG:0:50}"'..."}'

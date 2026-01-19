#!/bin/bash
# Custom Claude Code status line
# Shows: Task | Sprint | Done/Total | Sprint Days Left | Context %

# Безопасно определяем директорию проекта
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Colors (ANSI)
CYAN='\033[36m'
YELLOW='\033[33m'
GREEN='\033[32m'
RED='\033[31m'
MAGENTA='\033[35m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

OUTPUT=""

# 1. Current Task from ralph-progress.yaml
if [ -f "$PROJECT_DIR/.bmad/ralph-progress.yaml" ]; then
    TASK=$(grep "current_task:" "$PROJECT_DIR/.bmad/ralph-progress.yaml" 2>/dev/null | head -1 | sed 's/.*current_task: *"\([^"]*\)".*/\1/')
    if [ -n "$TASK" ] && [ "$TASK" != "null" ]; then
        OUTPUT="${CYAN}${TASK}${RESET}"
    fi
fi

# 2. Sprint number + days left
if [ -f "$PROJECT_DIR/.bmad/sprint-status.yaml" ]; then
    SPRINT=$(grep "current_sprint:" "$PROJECT_DIR/.bmad/sprint-status.yaml" 2>/dev/null | head -1 | sed 's/[^0-9]//g')

    # Get sprint end date
    END_DATE=$(grep -A20 "sprint_number: $SPRINT" "$PROJECT_DIR/.bmad/sprint-status.yaml" 2>/dev/null | grep "end_date:" | head -1 | sed 's/.*"\([^"]*\)".*/\1/')

    if [ -n "$SPRINT" ]; then
        [ -n "$OUTPUT" ] && OUTPUT="$OUTPUT ${DIM}│${RESET} "

        if [ -n "$END_DATE" ]; then
            # Calculate days left
            TODAY=$(date +%s)
            END=$(date -j -f "%Y-%m-%d" "$END_DATE" +%s 2>/dev/null || date -d "$END_DATE" +%s 2>/dev/null)
            if [ -n "$END" ]; then
                DAYS_LEFT=$(( (END - TODAY) / 86400 ))
                if [ $DAYS_LEFT -lt 0 ]; then
                    OUTPUT="${OUTPUT}${RED}S${SPRINT} overdue${RESET}"
                elif [ $DAYS_LEFT -le 3 ]; then
                    OUTPUT="${OUTPUT}${RED}S${SPRINT} ${DAYS_LEFT}d${RESET}"
                else
                    OUTPUT="${OUTPUT}${YELLOW}S${SPRINT} ${DAYS_LEFT}d${RESET}"
                fi
            else
                OUTPUT="${OUTPUT}${YELLOW}S${SPRINT}${RESET}"
            fi
        else
            OUTPUT="${OUTPUT}${YELLOW}S${SPRINT}${RESET}"
        fi
    fi
fi

# 3. Tasks: completed/total in current sprint
if [ -f "$PROJECT_DIR/.bmad/task-queue.yaml" ]; then
    # Count from summary section (more reliable)
    TOTAL=$(grep "total_tasks:" "$PROJECT_DIR/.bmad/task-queue.yaml" 2>/dev/null | head -1 | sed 's/[^0-9]//g') || TOTAL=0
    DONE=$(grep "completed_tasks:" "$PROJECT_DIR/.bmad/task-queue.yaml" 2>/dev/null | head -1 | sed 's/[^0-9]//g') || DONE=0

    # Ensure numeric
    TOTAL=${TOTAL:-0}
    DONE=${DONE:-0}
    PENDING=$((TOTAL - DONE))

    if [ "$TOTAL" -gt 0 ]; then
        [ -n "$OUTPUT" ] && OUTPUT="$OUTPUT ${DIM}│${RESET} "
        OUTPUT="${OUTPUT}${GREEN}✓${DONE}${RESET}${DIM}/${TOTAL}${RESET}"
        if [ "$PENDING" -gt 0 ]; then
            OUTPUT="${OUTPUT} ${DIM}(${PENDING} left)${RESET}"
        fi
    fi
fi

# 4. Context usage (tokens until compact)
# Claude Code context limit ~200k tokens
CONTEXT_LIMIT=200000
if [ -n "$CLAUDE_CONTEXT_TOKENS" ]; then
    PERCENT=$(echo "scale=0; $CLAUDE_CONTEXT_TOKENS * 100 / $CONTEXT_LIMIT" | bc 2>/dev/null)
    REMAINING=$((CONTEXT_LIMIT - CLAUDE_CONTEXT_TOKENS))
    REMAINING_K=$(echo "scale=1; $REMAINING / 1000" | bc 2>/dev/null)

    [ -n "$OUTPUT" ] && OUTPUT="$OUTPUT ${DIM}│${RESET} "

    if [ "$PERCENT" -ge 80 ]; then
        OUTPUT="${OUTPUT}${RED}${PERCENT}%${RESET} ${DIM}(${REMAINING_K}k left)${RESET}"
    elif [ "$PERCENT" -ge 50 ]; then
        OUTPUT="${OUTPUT}${YELLOW}${PERCENT}%${RESET} ${DIM}(${REMAINING_K}k left)${RESET}"
    else
        OUTPUT="${OUTPUT}${GREEN}${PERCENT}%${RESET} ${DIM}(${REMAINING_K}k left)${RESET}"
    fi
fi

# Output
if [ -n "$OUTPUT" ]; then
    echo -e "$OUTPUT"
fi

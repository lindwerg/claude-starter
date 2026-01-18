#!/bin/bash
###
# PreToolUse Hook - BACKPRESSURE ENFORCEMENT
# Blocks Edit/Write if quality gates fail during Ralph Loop
#
# Real enforcement, not just instructions!
###

set -e

# Start timing for metrics
START_TIME=$(date +%s%3N)

INPUT=$(cat)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
RALPH_MARKER="$PROJECT_DIR/.bmad/ralph-in-progress"

# Load metrics helper
source "$PROJECT_DIR/.claude/hooks/lib/log-metric.sh" 2>/dev/null || true

# Only enforce during Ralph Loop
if [ ! -f "$RALPH_MARKER" ]; then
    DURATION=$(($(date +%s%3N) - START_TIME))
    log_metric "backpressure-gate" "PreToolUse" "$DURATION" "continue" "" "" ""
    echo '{"result":"continue"}'
    exit 0
fi

cd "$PROJECT_DIR"

# Skip gate checks for certain files (configs, tests, yamls)
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)
if [[ "$TOOL_INPUT" == *".yaml" ]] || [[ "$TOOL_INPUT" == *".yml" ]] || [[ "$TOOL_INPUT" == *".md" ]] || [[ "$TOOL_INPUT" == *".json" ]] || [[ "$TOOL_INPUT" == *".test."* ]] || [[ "$TOOL_INPUT" == *".spec."* ]]; then
    DURATION=$(($(date +%s%3N) - START_TIME))
    log_metric "backpressure-gate" "PreToolUse" "$DURATION" "continue" "$TOOL_NAME" "$TOOL_INPUT" ""
    echo '{"result":"continue"}'
    exit 0
fi

# Gate 1: TypeScript (if tsconfig exists)
if [ -f "tsconfig.json" ] || [ -f "backend/tsconfig.json" ]; then
    if ! pnpm typecheck > /tmp/typecheck-output.txt 2>&1; then
        # Extract first 10 errors with file paths and line numbers
        ERRORS=$(cat /tmp/typecheck-output.txt | grep -E "error TS[0-9]+" | head -10 | sed 's/^/  /')
        ERROR_COUNT=$(cat /tmp/typecheck-output.txt | grep -cE "error TS[0-9]+" || echo "0")
        AFFECTED_FILES=$(cat /tmp/typecheck-output.txt | grep -oE "^[^(]+\.tsx?" | sort -u | head -5 | sed 's/^/  - /')

        DURATION=$(($(date +%s%3N) - START_TIME))
        log_metric "backpressure-gate" "PreToolUse" "$DURATION" "block" "$TOOL_NAME" "$TOOL_INPUT" "TypeScript: $ERROR_COUNT errors"

        cat << EOF
{"result":"block","message":"❌ BACKPRESSURE BLOCKED: TypeScript errors!\n\n📊 Found $ERROR_COUNT typecheck error(s)\n\n🔍 First 10 errors:\n$ERRORS\n\n📁 Affected files:\n$AFFECTED_FILES\n\n✅ FIX BEFORE CONTINUING:\n1. Review errors: pnpm typecheck\n2. Fix type issues in affected files\n3. Verify: pnpm typecheck (should pass)\n\n💡 Common fixes:\n- Add missing type annotations\n- Import missing types\n- Fix null/undefined checks\n- Update interface properties"}
EOF
        exit 0
    fi
fi

# Gate 2: Lint (quick check, only if recent changes)
# Skip for now - lint can be slow. Uncomment if needed:
# if ! pnpm lint > /dev/null 2>&1; then
#     DURATION=$(($(date +%s%3N) - START_TIME))
#     log_metric "backpressure-gate" "PreToolUse" "$DURATION" "block" "$TOOL_NAME" "$TOOL_INPUT" "ESLint errors"
#     echo '{"result":"block","message":"❌ BACKPRESSURE: ESLint errors. Run pnpm lint to see."}'
#     exit 0
# fi

# All gates passed
DURATION=$(($(date +%s%3N) - START_TIME))
log_metric "backpressure-gate" "PreToolUse" "$DURATION" "continue" "$TOOL_NAME" "$TOOL_INPUT" ""
echo '{"result":"continue"}'

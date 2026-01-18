#!/bin/bash
###
# PreToolUse Hook - BACKPRESSURE ENFORCEMENT
# Blocks Edit/Write if quality gates fail during Ralph Loop
#
# Real enforcement, not just instructions!
###

set -e

INPUT=$(cat)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
RALPH_MARKER="$PROJECT_DIR/.bmad/ralph-in-progress"

# Only enforce during Ralph Loop
if [ ! -f "$RALPH_MARKER" ]; then
    echo '{"result":"continue"}'
    exit 0
fi

cd "$PROJECT_DIR"

# Skip gate checks for certain files (configs, tests, yamls)
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null)
if [[ "$TOOL_INPUT" == *".yaml" ]] || [[ "$TOOL_INPUT" == *".yml" ]] || [[ "$TOOL_INPUT" == *".md" ]] || [[ "$TOOL_INPUT" == *".json" ]] || [[ "$TOOL_INPUT" == *".test."* ]] || [[ "$TOOL_INPUT" == *".spec."* ]]; then
    echo '{"result":"continue"}'
    exit 0
fi

# Gate 1: TypeScript (if tsconfig exists)
if [ -f "tsconfig.json" ] || [ -f "backend/tsconfig.json" ]; then
    if ! pnpm typecheck > /tmp/typecheck-output.txt 2>&1; then
        ERRORS=$(cat /tmp/typecheck-output.txt | head -5 | tr '\n' ' ')
        cat << EOF
{"result":"block","message":"❌ BACKPRESSURE BLOCKED: TypeScript errors!\n\n${ERRORS}\n\nFix typecheck errors before editing more files."}
EOF
        exit 0
    fi
fi

# Gate 2: Lint (quick check, only if recent changes)
# Skip for now - lint can be slow. Uncomment if needed:
# if ! pnpm lint > /dev/null 2>&1; then
#     echo '{"result":"block","message":"❌ BACKPRESSURE: ESLint errors. Run pnpm lint to see."}'
#     exit 0
# fi

# All gates passed
echo '{"result":"continue"}'

#!/bin/bash
###############################################################################
# SUBAGENT ENFORCEMENT HOOK (PreToolUse)
#
# Blocks Ralph Loop from directly editing src/ files without subagent.
# Forces use of Task tool for code changes during Ralph Loop.
#
# Logic:
# 1. Only active during Ralph Loop (.bmad/ralph-in-progress exists)
# 2. Whitelist: .bmad/, .claude/, *.md, *.yaml, *.json, prisma/ - allowed
# 3. src/ files: require .bmad/subagent-active marker (< 5 min old)
# 4. No marker = BLOCK with instructions to use Task tool
###############################################################################

set -e

INPUT=$(cat)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
RALPH_MARKER="$PROJECT_DIR/.bmad/ralph-in-progress"
SUBAGENT_MARKER="$PROJECT_DIR/.bmad/subagent-active"

# Only enforce during Ralph Loop
if [ ! -f "$RALPH_MARKER" ]; then
    echo '{"result":"continue"}'
    exit 0
fi

# Get target file path from input JSON
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null)

# Skip if no file path (shouldn't happen for Write/Edit)
if [ -z "$FILE_PATH" ]; then
    echo '{"result":"continue"}'
    exit 0
fi

# WHITELIST: Paths Ralph can edit directly (orchestration files)
if [[ "$FILE_PATH" == *".bmad/"* ]] || \
   [[ "$FILE_PATH" == *".claude/"* ]] || \
   [[ "$FILE_PATH" == *".md" ]] || \
   [[ "$FILE_PATH" == *".yaml" ]] || \
   [[ "$FILE_PATH" == *".yml" ]] || \
   [[ "$FILE_PATH" == *".json" ]] || \
   [[ "$FILE_PATH" == *"prisma/"* ]] || \
   [[ "$FILE_PATH" == *"docs/"* ]] || \
   [[ "$FILE_PATH" == *"openapi.yaml" ]] || \
   [[ "$FILE_PATH" == *"package.json" ]] || \
   [[ "$FILE_PATH" == *"tsconfig"* ]]; then
    echo '{"result":"continue"}'
    exit 0
fi

# CHECK: src/ requires subagent marker
if [[ "$FILE_PATH" == *"/src/"* ]] || [[ "$FILE_PATH" == *"frontend/src/"* ]] || [[ "$FILE_PATH" == *"backend/src/"* ]]; then

    # Check if subagent marker exists and is fresh (< 5 min old)
    if [ -f "$SUBAGENT_MARKER" ]; then
        # Get marker modification time (macOS vs Linux)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            MARKER_TIME=$(stat -f %m "$SUBAGENT_MARKER" 2>/dev/null || echo 0)
        else
            MARKER_TIME=$(stat -c %Y "$SUBAGENT_MARKER" 2>/dev/null || echo 0)
        fi

        NOW=$(date +%s)
        AGE=$((NOW - MARKER_TIME))

        # Fresh marker (< 5 minutes = 300 seconds) - allow
        if [ "$AGE" -lt 300 ]; then
            echo '{"result":"continue"}'
            exit 0
        fi
    fi

    # NO valid subagent marker -> BLOCK
    cat << 'EOF'
{"result":"block","message":"🚫 SUBAGENT REQUIRED\n\nRalph Loop cannot edit src/ files directly.\n\nYou MUST use Task tool to spawn a subagent:\n```\nTask({\n  subagent_type: \"frontend-agent\",  // or backend-agent\n  description: \"Execute TASK-XXX\",\n  prompt: \"... task details ...\"\n})\n```\n\nThe subagent will automatically create .bmad/subagent-active marker.\n\n📋 Allowed direct edits:\n- .bmad/, .claude/, docs/\n- *.md, *.yaml, *.json\n- prisma/, openapi.yaml"}
EOF
    exit 0
fi

# Default: allow non-src files
echo '{"result":"continue"}'

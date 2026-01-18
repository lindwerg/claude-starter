#!/bin/bash
###
# SessionStart Hook - Detect interrupted Ralph Loop and prompt to resume
###

set -e

INPUT=$(cat)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
RALPH_MARKER="$PROJECT_DIR/.bmad/ralph-in-progress"

# Check if Ralph was interrupted
if [ -f "$RALPH_MARKER" ]; then
    STARTED_AT=$(cat "$RALPH_MARKER" 2>/dev/null || echo "unknown")

    cat << EOF
{
    "result": "continue",
    "message": "🔄 RALPH LOOP INTERRUPTED\n\nRalph was running (started: $STARTED_AT)\n\nTo continue: /ralph-loop --resume\nTo abort: rm .bmad/ralph-in-progress"
}
EOF
else
    echo '{"result":"continue"}'
fi

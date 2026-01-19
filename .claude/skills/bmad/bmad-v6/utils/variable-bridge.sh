#!/bin/bash
# variable-bridge.sh - Bridge between step-* skills and BMAD commands
# Version: 1.0.0
# Purpose: Load answers from YAML and pass to BMAD commands as environment variables

set -euo pipefail

# Usage validation
if [ $# -lt 2 ]; then
    echo "Usage: variable-bridge.sh <command> <answers-yaml>" >&2
    echo "Example: variable-bridge.sh product-brief /tmp/step2-answers.yaml" >&2
    exit 1
fi

COMMAND="$1"
ANSWERS_FILE="$2"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Validate answers file exists
if [ ! -f "$ANSWERS_FILE" ]; then
    echo "Error: Answers file not found: $ANSWERS_FILE" >&2
    exit 1
fi

# Validate command file exists
COMMAND_FILE="$PROJECT_DIR/.claude/commands/${COMMAND}.md"
if [ ! -f "$COMMAND_FILE" ]; then
    echo "Error: Command file not found: $COMMAND_FILE" >&2
    exit 1
fi

# Load BMAD config if available
if [ -f "$PROJECT_DIR/.claude/skills/bmad/bmad-v6/scripts/load-config.sh" ]; then
    source "$PROJECT_DIR/.claude/skills/bmad/bmad-v6/scripts/load-config.sh"
fi

# Export answers as environment variables
# Format: YAML key (snake_case) → ENV var (BMAD_UPPER_SNAKE_CASE)
echo "[variable-bridge] Loading answers from: $ANSWERS_FILE"

# Parse YAML and export variables
# Note: This is a simple parser - for production consider using yq
while IFS=': ' read -r key value; do
    # Skip empty lines and comments
    [[ -z "$key" ]] && continue
    [[ "$key" =~ ^# ]] && continue

    # Skip metadata fields
    [[ "$key" == "collected_at" ]] && continue
    [[ "$key" == "collected_by" ]] && continue

    # Convert YAML key to ENV var
    # executive_summary → EXECUTIVE_SUMMARY
    # problem-statement → PROBLEM_STATEMENT
    env_key=$(echo "$key" | tr '[:lower:]' '[:upper:]' | tr '-' '_' | tr ' ' '_')

    # Remove leading/trailing whitespace and quotes from value
    clean_value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//')

    # Export as BMAD_* variable
    export "BMAD_${env_key}=${clean_value}"
    echo "[variable-bridge] Exported: BMAD_${env_key}" >&2
done < "$ANSWERS_FILE"

# Set batch mode flag
export BMAD_BATCH_MODE="true"
export BMAD_ANSWERS_FILE="$ANSWERS_FILE"

echo "[variable-bridge] Calling BMAD command: $COMMAND"

# Call BMAD command
# Note: The command .md file contains instructions for Claude
# This bridge makes variables available in the environment
# The actual execution happens in Claude Code with these env vars

# Create result marker
RESULT_FILE="/tmp/bmad-result-$$yaml"
cat > "$RESULT_FILE" <<EOF
command: $COMMAND
answers_file: $ANSWERS_FILE
batch_mode: true
status: ready
timestamp: $(date -Iseconds)
EOF

echo "[variable-bridge] ✓ Bridge setup complete"
echo "[variable-bridge] Environment variables exported"
echo "[variable-bridge] Ready for BMAD command execution"
echo "[variable-bridge] Result file: $RESULT_FILE"

# Return success
exit 0

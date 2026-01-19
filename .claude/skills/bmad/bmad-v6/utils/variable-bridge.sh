#!/bin/bash
# variable-bridge.sh - Bridge between step-* skills and BMAD commands
# Version: 2.0.0 - Uses yq for proper YAML parsing
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

# Validate command file exists (check PROJECT FIRST, then global)
COMMAND_FILE="$PROJECT_DIR/.claude/commands/${COMMAND}.md"
if [ ! -f "$COMMAND_FILE" ]; then
    # Fallback: try global location (for backwards compatibility)
    COMMAND_FILE="$HOME/.claude/commands/${COMMAND}.md"
    if [ ! -f "$COMMAND_FILE" ]; then
        echo "Error: Command file not found in project .claude/commands/ or ~/.claude/commands/" >&2
        echo "       Looking for: ${COMMAND}.md" >&2
        exit 1
    fi
fi

echo "[variable-bridge] Using command file: $COMMAND_FILE" >&2

# Load BMAD config if available (check PROJECT FIRST)
if [ -f "$PROJECT_DIR/.claude/skills/bmad/bmad-v6/scripts/load-config.sh" ]; then
    source "$PROJECT_DIR/.claude/skills/bmad/bmad-v6/scripts/load-config.sh"
elif [ -f "$HOME/.claude/skills/bmad/bmad-v6/scripts/load-config.sh" ]; then
    # Fallback: global BMAD installation
    source "$HOME/.claude/skills/bmad/bmad-v6/scripts/load-config.sh"
fi

# Export answers as environment variables
echo "[variable-bridge] Loading answers from: $ANSWERS_FILE"

# Check if yq is available (proper YAML parser)
if command -v yq &> /dev/null; then
    echo "[variable-bridge] Using yq for YAML parsing" >&2

    # Get all top-level keys
    keys=$(yq eval 'keys | .[]' "$ANSWERS_FILE")

    # Export each key as BMAD_* variable
    while IFS= read -r key; do
        # Skip metadata fields
        [[ "$key" == "collected_at" ]] && continue
        [[ "$key" == "collected_by" ]] && continue

        # Get value (handles multiline, preserves formatting)
        value=$(yq eval ".${key}" "$ANSWERS_FILE")

        # Convert key to ENV var format
        env_key=$(echo "$key" | tr '[:lower:]' '[:upper:]' | tr '-' '_' | tr ' ' '_')

        # Export as BMAD_* variable
        export "BMAD_${env_key}=${value}"
        echo "[variable-bridge] Exported: BMAD_${env_key} (${#value} chars)" >&2
    done <<< "$keys"

else
    # Fallback: Python YAML parser (more reliable than bash)
    echo "[variable-bridge] Using python for YAML parsing" >&2

    # Use eval to export variables in parent shell (not subshell)
    eval "$(python3 -c "
import yaml
import base64
import sys

with open('$ANSWERS_FILE', 'r', encoding='utf-8') as f:
    data = yaml.safe_load(f)

if not isinstance(data, dict):
    print('Error: YAML must be a dictionary', file=sys.stderr)
    sys.exit(1)

for key, value in data.items():
    # Skip metadata
    if key in ['collected_at', 'collected_by']:
        continue

    # Convert key to ENV var format
    env_key = key.upper().replace('-', '_').replace(' ', '_')

    # Convert value to string (handles multiline)
    if isinstance(value, (list, dict)):
        import json
        str_value = json.dumps(value, ensure_ascii=False)
    else:
        str_value = str(value)

    # Base64 encode to safely pass through bash (handles newlines, quotes, etc)
    b64_value = base64.b64encode(str_value.encode('utf-8')).decode('ascii')

    # Output export statement that will be eval'd
    print(f'export BMAD_{env_key}=\\$(echo {b64_value} | base64 -d)')

    # Log to stderr (won't be eval'd)
    sys.stderr.write(f'[variable-bridge] Exported: BMAD_{env_key} ({len(str_value)} chars)\\n')
")"
fi

# Set batch mode flag
export BMAD_BATCH_MODE="true"
export BMAD_ANSWERS_FILE="$ANSWERS_FILE"

echo "[variable-bridge] Calling BMAD command: $COMMAND"

# Create result marker
RESULT_FILE="/tmp/bmad-result-$$.yaml"
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

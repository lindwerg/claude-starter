#!/bin/bash
# Test: variable-bridge.sh should check PROJECT first, then global

set -e

TEST_DIR=$(mktemp -d)
PROJECT_DIR="$TEST_DIR/project"
GLOBAL_DIR="$TEST_DIR/global"

mkdir -p "$PROJECT_DIR/.claude/commands"
mkdir -p "$GLOBAL_DIR/.claude/commands"

# Create test YAML
cat > "$TEST_DIR/answers.yaml" << 'EOF'
test_var: "value"
EOF

# Test 1: Project-local command should take precedence
echo "Test 1: Project-local command takes precedence"
cat > "$PROJECT_DIR/.claude/commands/test-cmd.md" << 'EOF'
# Project command
EOF

cat > "$GLOBAL_DIR/.claude/commands/test-cmd.md" << 'EOF'
# Global command
EOF

# Save real script path before changing HOME
SCRIPT_PATH="/Users/kirill/.claude/skills/bmad/bmad-v6/utils/variable-bridge.sh"

export HOME="$GLOBAL_DIR"
export CLAUDE_PROJECT_DIR="$PROJECT_DIR"

# Run variable-bridge
output=$(bash "$SCRIPT_PATH" test-cmd "$TEST_DIR/answers.yaml" 2>&1)

if echo "$output" | grep -q "$PROJECT_DIR/.claude/commands/test-cmd.md"; then
    echo "✅ Test 1 passed: Project command used"
else
    echo "❌ Test 1 failed: Expected project command, got:"
    echo "$output"
    rm -rf "$TEST_DIR"
    exit 1
fi

# Cleanup
rm -rf "$TEST_DIR"

echo ""
echo "✅ Test passed!"

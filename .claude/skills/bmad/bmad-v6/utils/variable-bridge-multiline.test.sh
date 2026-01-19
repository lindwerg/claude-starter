#!/bin/bash
# Test: variable-bridge.sh должен правильно парсить многострочные YAML значения

set -e

TEST_DIR=$(mktemp -d)
ANSWERS_FILE="$TEST_DIR/answers.yaml"
PROJECT_DIR="$TEST_DIR/project"

# Setup
mkdir -p "$PROJECT_DIR/.claude/commands"
cat > "$PROJECT_DIR/.claude/commands/test.md" <<'EOF'
# Test command
EOF

# Create YAML with multiline values
cat > "$ANSWERS_FILE" <<'EOF'
collected_at: "2026-01-19T00:00:00Z"
collected_by: "test"
product_goals: |
  1. Достичь 100% консистентности AI-персонажа
  2. Автоматизировать 90% контент-рутины
  3. Создать 10-100 AI-блогеров на старте
key_metrics: |
  - MRR (ежемесячный доход)
  - Количество активных AI-блогеров
EOF

echo "Test: Multiline YAML parsing"

# Run variable-bridge.sh and check for errors
export CLAUDE_PROJECT_DIR="$PROJECT_DIR"
cd "$PROJECT_DIR"

OUTPUT=$(bash ~/.claude/skills/bmad/bmad-v6/utils/variable-bridge.sh test "$ANSWERS_FILE" 2>&1)

# Test 1: Should NOT have "not a valid identifier" error
if echo "$OUTPUT" | grep -q "not a valid identifier"; then
    echo "❌ Test 1 FAILED: Parser breaks on multiline values"
    echo "$OUTPUT"
    rm -rf "$TEST_DIR"
    exit 1
fi
echo "✅ Test 1 PASSED: No identifier errors"

# Test 2: Should complete successfully
if ! echo "$OUTPUT" | grep -q "Bridge setup complete"; then
    echo "❌ Test 2 FAILED: Script did not complete"
    echo "$OUTPUT"
    rm -rf "$TEST_DIR"
    exit 1
fi
echo "✅ Test 2 PASSED: Script completed successfully"

# Test 3: Should export variables (check log output)
if ! echo "$OUTPUT" | grep -q "Exported: BMAD_PRODUCT_GOALS"; then
    echo "❌ Test 3 FAILED: BMAD_PRODUCT_GOALS not exported"
    echo "$OUTPUT"
    rm -rf "$TEST_DIR"
    exit 1
fi
echo "✅ Test 3 PASSED: Variables exported"

echo ""
echo "✅ ALL TESTS PASSED: Multiline YAML parsed correctly"

# Cleanup
rm -rf "$TEST_DIR"

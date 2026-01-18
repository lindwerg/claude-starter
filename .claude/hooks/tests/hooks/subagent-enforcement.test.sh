#!/bin/bash
###############################################################################
# Test: subagent-enforcement.sh
#
# Tests the subagent enforcement hook for blocking/allowing src/ edits
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK="$HOOK_DIR/subagent-enforcement.sh"

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Helper: Run test
run_test() {
    local test_name="$1"
    local input_json="$2"
    local expected_result="$3"  # "continue" or "block"

    echo -n "  Testing: $test_name... "

    local output=$(echo "$input_json" | bash "$HOOK")
    local result=$(echo "$output" | jq -r '.result' 2>/dev/null)

    if [ "$result" = "$expected_result" ]; then
        echo "✓ PASS"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ FAIL (expected: $expected_result, got: $result)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Setup
export CLAUDE_PROJECT_DIR="/tmp/hook-test-$$"
mkdir -p "$CLAUDE_PROJECT_DIR/.bmad"
mkdir -p "$CLAUDE_PROJECT_DIR/src"

# Cleanup function
cleanup() {
    rm -rf "$CLAUDE_PROJECT_DIR"
}
trap cleanup EXIT

echo ""
echo "=== Testing subagent-enforcement.sh ==="
echo ""

# ============================================================================
# Test Suite 1: Ralph Loop Not Active
# ============================================================================

echo "Suite 1: Ralph Loop Not Active"

run_test "Allow edit when Ralph not active" \
    '{"tool_name":"Edit","tool_input":{"file_path":"'$CLAUDE_PROJECT_DIR'/src/app.ts"}}' \
    "continue"

# ============================================================================
# Test Suite 2: Ralph Active, Whitelisted Files
# ============================================================================

echo ""
echo "Suite 2: Ralph Active, Whitelisted Files"

# Activate Ralph Loop
touch "$CLAUDE_PROJECT_DIR/.bmad/ralph-in-progress"

run_test "Allow .bmad/ file edits" \
    '{"tool_name":"Edit","tool_input":{"file_path":"'$CLAUDE_PROJECT_DIR'/.bmad/task-queue.yaml"}}' \
    "continue"

run_test "Allow .claude/ file edits" \
    '{"tool_name":"Edit","tool_input":{"file_path":"'$CLAUDE_PROJECT_DIR'/.claude/settings.json"}}' \
    "continue"

run_test "Allow .md file edits" \
    '{"tool_name":"Edit","tool_input":{"file_path":"'$CLAUDE_PROJECT_DIR'/README.md"}}' \
    "continue"

run_test "Allow .yaml file edits" \
    '{"tool_name":"Edit","tool_input":{"file_path":"'$CLAUDE_PROJECT_DIR'/docker-compose.yaml"}}' \
    "continue"

run_test "Allow openapi.yaml edits" \
    '{"tool_name":"Edit","tool_input":{"file_path":"'$CLAUDE_PROJECT_DIR'/openapi.yaml"}}' \
    "continue"

run_test "Allow prisma/ file edits" \
    '{"tool_name":"Edit","tool_input":{"file_path":"'$CLAUDE_PROJECT_DIR'/prisma/schema.prisma"}}' \
    "continue"

# ============================================================================
# Test Suite 3: Ralph Active, src/ Without Subagent Marker
# ============================================================================

echo ""
echo "Suite 3: Ralph Active, src/ Without Subagent Marker"

run_test "Block src/ edit without marker" \
    '{"tool_name":"Edit","tool_input":{"file_path":"'$CLAUDE_PROJECT_DIR'/src/app.ts"}}' \
    "block"

run_test "Block backend/src/ edit without marker" \
    '{"tool_name":"Edit","tool_input":{"file_path":"'$CLAUDE_PROJECT_DIR'/backend/src/index.ts"}}' \
    "block"

run_test "Block frontend/src/ edit without marker" \
    '{"tool_name":"Edit","tool_input":{"file_path":"'$CLAUDE_PROJECT_DIR'/frontend/src/App.tsx"}}' \
    "block"

# ============================================================================
# Test Suite 4: Ralph Active, src/ WITH Subagent Marker (UUID)
# ============================================================================

echo ""
echo "Suite 4: Ralph Active, src/ WITH Subagent Marker"

# Create subagent marker with UUID (new approach)
echo "12345-67890-$(date +%s)" > "$CLAUDE_PROJECT_DIR/.bmad/subagent-active"

run_test "Allow src/ edit with UUID marker" \
    '{"tool_name":"Edit","tool_input":{"file_path":"'$CLAUDE_PROJECT_DIR'/src/app.ts"}}' \
    "continue"

run_test "Allow backend/src/ edit with UUID marker" \
    '{"tool_name":"Edit","tool_input":{"file_path":"'$CLAUDE_PROJECT_DIR'/backend/src/index.ts"}}' \
    "continue"

run_test "Allow frontend/src/ edit with UUID marker" \
    '{"tool_name":"Edit","tool_input":{"file_path":"'$CLAUDE_PROJECT_DIR'/frontend/src/App.tsx"}}' \
    "continue"

# ============================================================================
# Test Suite 5: Edge Cases
# ============================================================================

echo ""
echo "Suite 5: Edge Cases"

# Empty marker should block (0 bytes)
> "$CLAUDE_PROJECT_DIR/.bmad/subagent-active"

run_test "Block src/ edit with empty marker" \
    '{"tool_name":"Edit","tool_input":{"file_path":"'$CLAUDE_PROJECT_DIR'/src/app.ts"}}' \
    "block"

# No file_path in input
run_test "Allow when no file_path in input" \
    '{"tool_name":"Edit","tool_input":{}}' \
    "continue"

# ============================================================================
# Results
# ============================================================================

echo ""
echo "========================================="
echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
echo "========================================="
echo ""

if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
else
    exit 0
fi

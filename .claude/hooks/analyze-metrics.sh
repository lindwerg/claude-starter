#!/bin/bash
###############################################################################
# Hook Metrics Analyzer
#
# Analyzes hook execution metrics from .claude/hooks/metrics/*.jsonl files
#
# Usage:
#   bash analyze-metrics.sh [date]  # date in YYYY-MM-DD format (default: today)
###############################################################################

set -e

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
METRICS_DIR="$PROJECT_DIR/.claude/hooks/metrics"

# Get date (default: today)
DATE="${1:-$(date +%Y-%m-%d)}"
LOG_FILE="$METRICS_DIR/$DATE.jsonl"

if [ ! -f "$LOG_FILE" ]; then
    echo "❌ No metrics found for $DATE"
    echo "Log file: $LOG_FILE"
    exit 1
fi

echo "📊 Hook Metrics Analysis - $DATE"
echo "════════════════════════════════════════"
echo ""

# Total executions
TOTAL=$(wc -l < "$LOG_FILE")
echo "Total hook executions: $TOTAL"
echo ""

# By result
CONTINUE_COUNT=$(grep -c '"result":"continue"' "$LOG_FILE" || echo "0")
BLOCK_COUNT=$(grep -c '"result":"block"' "$LOG_FILE" || echo "0")
echo "Results:"
echo "  ✓ Continue: $CONTINUE_COUNT ($(awk "BEGIN {printf \"%.1f\", ($CONTINUE_COUNT/$TOTAL)*100}")%)"
echo "  ✗ Block:    $BLOCK_COUNT ($(awk "BEGIN {printf \"%.1f\", ($BLOCK_COUNT/$TOTAL)*100}")%)"
echo ""

# By hook
echo "By hook:"
jq -r '.hook_name' "$LOG_FILE" | sort | uniq -c | sort -rn | awk '{printf "  %-30s %d\n", $2, $1}'
echo ""

# Average duration
echo "Performance (average duration):"
jq -r '. | "\(.hook_name) \(.duration_ms)"' "$LOG_FILE" | \
    awk '{hook[$1]+=$2; count[$1]++} END {for (h in hook) printf "  %-30s %.0f ms\n", h, hook[h]/count[h]}' | \
    sort -k2 -n
echo ""

# Slowest executions
echo "Slowest executions:"
jq -r '. | "\(.duration_ms) ms - \(.hook_name) (\(.event_type)) - \(.tool_name // "N/A")"' "$LOG_FILE" | \
    sort -rn | head -10
echo ""

# Blocks by hook
echo "Blocks by hook:"
grep '"result":"block"' "$LOG_FILE" | jq -r '.hook_name' | sort | uniq -c | sort -rn | awk '{printf "  %-30s %d\n", $2, $1}'
echo ""

# Errors
ERROR_COUNT=$(grep -c '"error"' "$LOG_FILE" || echo "0")
if [ "$ERROR_COUNT" -gt 0 ]; then
    echo "❌ Errors detected: $ERROR_COUNT"
    grep '"error"' "$LOG_FILE" | jq -r '. | "  [\(.hook_name)] \(.error)"' | head -5
    echo ""
fi

# Summary
echo "════════════════════════════════════════"
echo "Summary:"
echo "  Total executions: $TOTAL"
echo "  Block rate: $(awk "BEGIN {printf \"%.1f\", ($BLOCK_COUNT/$TOTAL)*100}")%"
echo "  Errors: $ERROR_COUNT"
echo ""
echo "💡 Tip: Use 'jq' for custom queries:"
echo "  jq '.hook_name' $LOG_FILE | sort | uniq -c"
echo "  jq 'select(.result==\"block\")' $LOG_FILE"

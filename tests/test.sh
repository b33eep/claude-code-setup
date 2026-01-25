#!/bin/bash

# Main test runner
# Usage: ./tests/test.sh [scenario...]
# Examples:
#   ./tests/test.sh              # Run all scenarios
#   ./tests/test.sh 01 02        # Run specific scenarios
#   ./tests/test.sh fresh        # Run scenarios matching "fresh"

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo ""
echo "Claude Code Setup - Test Suite"
echo "==============================="
echo "Project: $PROJECT_DIR"

# Find scenarios to run
SCENARIOS_DIR="$SCRIPT_DIR/scenarios"
SCENARIOS=()

if [ $# -eq 0 ]; then
    # Run all scenarios
    for f in "$SCENARIOS_DIR"/*.sh; do
        [ -f "$f" ] && SCENARIOS+=("$f")
    done
else
    # Run matching scenarios
    for pattern in "$@"; do
        for f in "$SCENARIOS_DIR"/*"$pattern"*.sh; do
            [ -f "$f" ] && SCENARIOS+=("$f")
        done
    done
fi

if [ ${#SCENARIOS[@]} -eq 0 ]; then
    echo "No scenarios found!"
    exit 1
fi

echo "Scenarios: ${#SCENARIOS[@]}"

# Track results
TOTAL_PASSED=0
TOTAL_FAILED=0

# Run each scenario
for scenario in "${SCENARIOS[@]}"; do
    scenario_name=$(basename "$scenario" .sh)

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Scenario: $scenario_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Run scenario as standalone script, capture exit code
    if bash "$scenario" "$PROJECT_DIR"; then
        ((TOTAL_PASSED++)) || true
    else
        ((TOTAL_FAILED++)) || true
    fi
done

# Print summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$TOTAL_FAILED" -eq 0 ]; then
    echo -e "${GREEN}All scenarios passed!${NC} ($TOTAL_PASSED scenarios)"
else
    echo -e "${RED}Some scenarios failed!${NC} ($TOTAL_PASSED passed, $TOTAL_FAILED failed)"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit "$TOTAL_FAILED"

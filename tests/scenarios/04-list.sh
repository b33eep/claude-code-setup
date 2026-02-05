#!/bin/bash

# Scenario: List modules with --list

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

scenario "List before installation"

output=$("$PROJECT_DIR/install.sh" --list 2>&1)

if echo "$output" | grep -q "pdf-reader"; then
    pass "--list shows available MCP"
else
    fail "--list should show available MCP"
fi

if echo "$output" | grep -q "standards-python"; then
    pass "--list shows available skills"
else
    fail "--list should show available skills"
fi

scenario "List after installation"

# Install pdf-reader and standards-python only
# Skill order (alphabetical): 1=create-slidev, 2=skill-creator, 3=standards-javascript,
#                             4=standards-python, 5=standards-shell, 6=standards-typescript
run_install_expect '
    # MCP: pdf-reader is pre-selected, confirm
    confirm_mcp

    # Skills: keep only standards-python (#4)
    select_only_skill 6

    # Decline status line
    decline_statusline
' > /dev/null

output=$("$PROJECT_DIR/install.sh" --list 2>&1)

if echo "$output" | grep -q "pdf-reader"; then
    pass "--list shows pdf-reader"
else
    fail "--list should show pdf-reader"
fi

if echo "$output" | grep -q "standards-python"; then
    pass "--list shows standards-python"
else
    fail "--list should show standards-python"
fi

# Print summary
print_summary

#!/bin/bash

# Scenario: Removing modules with --remove

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

scenario "Initial install with modules"

# Install with pdf-reader MCP and standards-python skill
run_install_expect '
    # Keep pdf-reader (pre-selected)
    confirm_mcp

    # Select only standards-python (#5 of 8 available)
    select_only_skill 7

    # Decline status line
    decline_statusline
' > /dev/null

assert_json_exists "$INSTALLED_FILE" '.mcp[] | select(. == "pdf-reader")' "pdf-reader installed"
assert_json_exists "$INSTALLED_FILE" '.skills[] | select(. == "standards-python")' "standards-python installed"

# Verify dynamic tables contain installed modules
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "pdf-reader" "CLAUDE.md MCP table has pdf-reader"
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "standards-python" "CLAUDE.md skills table has standards-python"

scenario "Remove MCP server"

# Remove pdf-reader (position 1 in remove list)
run_remove_expect '
    toggle_remove 1
    confirm_remove
    accept_remove
' > /dev/null

# Verify removal
if jq -e '.mcp[] | select(. == "pdf-reader")' "$INSTALLED_FILE" > /dev/null 2>&1; then
    fail "pdf-reader should be removed from installed.json"
else
    pass "pdf-reader removed from installed.json"
fi

if jq -e '.mcpServers["pdf-reader"]' "$MCP_CONFIG_FILE" > /dev/null 2>&1; then
    fail "pdf-reader should be removed from .claude.json"
else
    pass "pdf-reader removed from .claude.json"
fi

# Verify CLAUDE.md no longer references pdf-reader in MCP table
if grep -q '`pdf-reader`' "$CLAUDE_DIR/CLAUDE.md"; then
    fail "pdf-reader should be removed from CLAUDE.md MCP table"
else
    pass "pdf-reader removed from CLAUDE.md MCP table"
fi

scenario "Remove skill"

# standards-python is now position 1 (after pdf-reader was removed)
run_remove_expect '
    toggle_remove 1
    confirm_remove
    accept_remove
' > /dev/null

# Verify skill removal
if jq -e '.skills[] | select(. == "standards-python")' "$INSTALLED_FILE" > /dev/null 2>&1; then
    fail "standards-python should be removed from installed.json"
else
    pass "standards-python removed from installed.json"
fi

if [ -d "$CLAUDE_DIR/skills/standards-python" ]; then
    fail "standards-python directory should be removed"
else
    pass "standards-python directory removed"
fi

# Verify CLAUDE.md no longer references standards-python in tables
if grep -q '`standards-python`' "$CLAUDE_DIR/CLAUDE.md"; then
    fail "standards-python should be removed from CLAUDE.md tables"
else
    pass "standards-python removed from CLAUDE.md tables"
fi

scenario "Remove with no modules shows message"

# Try to remove when nothing is installed
output=$(run_remove_expect '' 2>&1) || true

if echo "$output" | grep -q "No modules installed to remove"; then
    pass "Shows 'no modules' message when empty"
else
    fail "Should show 'no modules' message"
fi

scenario "Cancel remove does not delete"

# Re-install a skill first
run_add_expect '
    # No MCP
    confirm_mcp

    # Select standards-shell (#8 of 10 available)
    select_only_skill 8

    # Decline status line
    decline_statusline
' > /dev/null

assert_json_exists "$INSTALLED_FILE" '.skills[] | select(. == "standards-shell")' "standards-shell installed for cancel test"

# Try to remove but cancel
run_remove_expect '
    toggle_remove 1
    confirm_remove
    decline_remove
' > /dev/null

# Verify skill still exists
assert_json_exists "$INSTALLED_FILE" '.skills[] | select(. == "standards-shell")' "standards-shell still installed after cancel"
assert_dir_exists "$CLAUDE_DIR/skills/standards-shell" "standards-shell directory still exists after cancel"

scenario "--remove --yes is rejected"

# Try to use --remove with --yes flag
output=$(HOME="$TEST_DIR" "$PROJECT_DIR/install.sh" --remove --yes 2>&1) || true

if echo "$output" | grep -q "Remove requires interactive mode"; then
    pass "--remove --yes shows rejection message"
else
    fail "--remove --yes should show rejection message"
fi

# Verify module was NOT removed
assert_json_exists "$INSTALLED_FILE" '.skills[] | select(. == "standards-shell")' "standards-shell still installed after --yes rejection"

# Print summary
print_summary

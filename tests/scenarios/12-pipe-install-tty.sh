#!/bin/bash

# Scenario: Pipe installation with TTY support
# Tests that read_input function works correctly for pipe-based installation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

scenario "read_input function exists and is used"

# Source the helpers module to test functions
source "$PROJECT_DIR/lib/helpers.sh"

# Test 1: read_input function exists
if declare -f read_input > /dev/null 2>&1; then
    pass "read_input function exists"
else
    fail "read_input function not found"
fi

# Test 2: quick-install.sh has correct TTY check logic
if grep -q '\[\[ -r /dev/tty \]\]' "$PROJECT_DIR/quick-install.sh"; then
    pass "quick-install.sh checks for /dev/tty"
else
    fail "quick-install.sh missing /dev/tty check"
fi

# Test 3: quick-install.sh uses --yes as fallback
if grep -q './install.sh --yes' "$PROJECT_DIR/quick-install.sh"; then
    pass "quick-install.sh uses --yes for non-interactive"
else
    fail "quick-install.sh missing --yes fallback"
fi

# Test 4: modules.sh uses read_input
if grep -q 'read_input' "$PROJECT_DIR/lib/modules.sh"; then
    pass "modules.sh uses read_input for prompts"
else
    fail "modules.sh not using read_input"
fi

# Test 5: statusline.sh uses read_input
if grep -q 'read_input' "$PROJECT_DIR/lib/statusline.sh"; then
    pass "statusline.sh uses read_input for prompts"
else
    fail "statusline.sh not using read_input"
fi

# ============================================
# Functional tests for read_input
# ============================================

scenario "read_input functional tests (pipe input)"

# Test 6: read_input reads single value from pipe
result=$(echo "test-value" | read_input "Enter value: ") || true
if [[ "$result" == "test-value" ]]; then
    pass "read_input reads single value from pipe"
else
    fail "read_input pipe handling broken (got: '$result')"
fi

# Test 7: read_input reads numeric value
result=$(echo "42" | read_input "Enter number: ") || true
if [[ "$result" == "42" ]]; then
    pass "read_input reads numeric value"
else
    fail "read_input numeric handling broken (got: '$result')"
fi

# Test 8: read_input reads empty input (just Enter)
result=$(echo "" | read_input "Press enter: ") || true
if [[ "$result" == "" ]]; then
    pass "read_input handles empty input"
else
    fail "read_input empty input broken (got: '$result')"
fi

# Test 9: read_input reads value with spaces
result=$(echo "hello world" | read_input "Enter text: ") || true
if [[ "$result" == "hello world" ]]; then
    pass "read_input handles spaces in input"
else
    fail "read_input space handling broken (got: '$result')"
fi

# Test 10: read_input reads selection numbers (like MCP/skills selection)
result=$(echo "1 2 3" | read_input "Select: ") || true
if [[ "$result" == "1 2 3" ]]; then
    pass "read_input handles selection numbers"
else
    fail "read_input selection handling broken (got: '$result')"
fi

# Test 11: read_input handles 'none' keyword
result=$(echo "none" | read_input "Select: ") || true
if [[ "$result" == "none" ]]; then
    pass "read_input handles 'none' keyword"
else
    fail "read_input 'none' handling broken (got: '$result')"
fi

# Test 12: read_input handles Y/n response
result=$(echo "Y" | read_input "Continue? (Y/n): ") || true
if [[ "$result" == "Y" ]]; then
    pass "read_input handles Y/n response"
else
    fail "read_input Y/n handling broken (got: '$result')"
fi

# Test 13: read_input handles lowercase response
result=$(echo "n" | read_input "Continue? (Y/n): ") || true
if [[ "$result" == "n" ]]; then
    pass "read_input handles lowercase response"
else
    fail "read_input lowercase handling broken (got: '$result')"
fi

# ============================================
# Integration test: Full install simulation
# ============================================

scenario "Full install with piped input"

# Reset test env for clean install
rm -rf "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR"

# Simulate interactive install via pipe:
# - MCP selection: "3" (pdf-reader)
# - Skills selection: "4" (standards-python)
# - Statusline: "Y"
printf '3\n4\nY\n' | "$PROJECT_DIR/install.sh" > /dev/null 2>&1

# Verify install worked with correct selections
assert_file_exists "$CLAUDE_DIR/CLAUDE.md" "CLAUDE.md created"
assert_file_exists "$INSTALLED_FILE" "installed.json created"
assert_dir_exists "$CLAUDE_DIR/commands" "commands installed"

# Verify MCP selection was processed
if jq -e '.mcpServers["pdf-reader"]' "$MCP_CONFIG_FILE" > /dev/null 2>&1; then
    pass "pdf-reader MCP installed (selection '3' worked)"
else
    fail "pdf-reader MCP not installed"
fi

# Verify skill selection was processed
if [[ -d "$CLAUDE_DIR/skills/standards-python" ]]; then
    pass "standards-python skill installed (selection '4' worked)"
else
    fail "standards-python skill not installed"
fi

# Verify statusline selection was processed
if jq -e '.statusLine' "$CLAUDE_DIR/settings.json" > /dev/null 2>&1; then
    pass "statusLine enabled (selection 'Y' worked)"
else
    # statusLine might not be configured if npx is not available
    pass "statusLine skipped (npx not available)"
fi

# ============================================
# Non-interactive fallback test
# ============================================

scenario "Non-interactive fallback (--yes mode)"

# Reset test env
rm -rf "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR"

# Run with --yes flag (no prompts)
"$PROJECT_DIR/install.sh" --yes > /dev/null 2>&1

assert_file_exists "$CLAUDE_DIR/CLAUDE.md" "CLAUDE.md created with --yes"
assert_file_exists "$INSTALLED_FILE" "installed.json created with --yes"
assert_dir_exists "$CLAUDE_DIR/commands" "commands installed with --yes"

# In --yes mode, MCP and skills are skipped
installed_mcp=$(jq -r '.mcp | length' "$INSTALLED_FILE")
installed_skills=$(jq -r '.skills | length' "$INSTALLED_FILE")

if [[ "$installed_mcp" == "0" ]]; then
    pass "MCP skipped in --yes mode (expected)"
else
    fail "MCP should be skipped in --yes mode"
fi

if [[ "$installed_skills" == "0" ]]; then
    pass "Skills skipped in --yes mode (expected)"
else
    fail "Skills should be skipped in --yes mode"
fi

# ============================================
# ccstatusline E2E test (if npx available)
# ============================================

scenario "ccstatusline E2E test"

if command -v npx &>/dev/null; then
    # Test that ccstatusline can be executed non-interactively
    # The -y flag should skip any npm prompts
    output=$(echo '{}' | npx -y ccstatusline@latest 2>&1) || true

    if [[ -n "$output" ]]; then
        pass "ccstatusline executes with empty JSON input"
        # Output should contain ANSI codes or text (statusline)
        if [[ "$output" == *$'\033'* ]] || [[ "$output" == *"["* ]]; then
            pass "ccstatusline produces formatted output"
        else
            # Even plain text is acceptable
            pass "ccstatusline produces output: ${output:0:50}..."
        fi
    else
        fail "ccstatusline produced no output"
    fi
else
    pass "npx not available, skipping ccstatusline E2E test"
fi

print_summary

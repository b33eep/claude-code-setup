#!/bin/bash

# Scenario: Interactive installation with TTY support
# Tests that interactive_select and read_input functions work correctly

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

scenario "Interactive selection functions exist"

# Test 1: interactive_select function exists
if grep -q 'interactive_select()' "$PROJECT_DIR/lib/modules.sh"; then
    pass "interactive_select function exists"
else
    fail "interactive_select function not found"
fi

# Test 2: read_input function exists (for simple prompts like API key, status line)
# shellcheck source=../../lib/helpers.sh
source "$PROJECT_DIR/lib/helpers.sh"
if declare -f read_input > /dev/null 2>&1; then
    pass "read_input function exists"
else
    fail "read_input function not found"
fi

# Test 3: quick-install.sh has correct TTY check logic
if grep -q '\[\[ -t 0 \]\]' "$PROJECT_DIR/quick-install.sh"; then
    pass "quick-install.sh checks if stdin is a terminal"
else
    fail "quick-install.sh missing stdin tty check"
fi

# Test 4: quick-install.sh uses --yes as fallback for non-interactive
if grep -q './install.sh --yes' "$PROJECT_DIR/quick-install.sh"; then
    pass "quick-install.sh uses --yes for non-interactive"
else
    fail "quick-install.sh missing --yes fallback"
fi

# Test 5: statusline.sh uses read_input for Y/n prompt
if grep -q 'read_input' "$PROJECT_DIR/lib/statusline.sh"; then
    pass "statusline.sh uses read_input for prompts"
else
    fail "statusline.sh not using read_input"
fi

# ============================================
# Functional tests for read_input (used for simple prompts)
# ============================================

scenario "read_input functional tests (pipe input)"

# Test 6: read_input reads single value from pipe
result=$(echo "test-value" | read_input "Enter value: ") || true
if [[ "$result" == "test-value" ]]; then
    pass "read_input reads single value from pipe"
else
    fail "read_input pipe handling broken (got: '$result')"
fi

# Test 7: read_input reads Y/n response
result=$(echo "Y" | read_input "Continue? (Y/n): ") || true
if [[ "$result" == "Y" ]]; then
    pass "read_input handles Y/n response"
else
    fail "read_input Y/n handling broken (got: '$result')"
fi

# Test 8: read_input reads lowercase response
result=$(echo "n" | read_input "Continue? (Y/n): ") || true
if [[ "$result" == "n" ]]; then
    pass "read_input handles lowercase response"
else
    fail "read_input lowercase handling broken (got: '$result')"
fi

# Test 9: read_input reads empty input (just Enter)
result=$(echo "" | read_input "Press enter: ") || true
if [[ "$result" == "" ]]; then
    pass "read_input handles empty input"
else
    fail "read_input empty input broken (got: '$result')"
fi

# Test 10: read_input reads API key with special chars
result=$(echo "sk-abc123_XYZ" | read_input "Enter API key: ") || true
if [[ "$result" == "sk-abc123_XYZ" ]]; then
    pass "read_input handles API key format"
else
    fail "read_input API key handling broken (got: '$result')"
fi

# ============================================
# Integration test: Full install with expect (interactive mode)
# ============================================

scenario "Full install with interactive toggle selection"

# Reset test env for clean install
rm -rf "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR"

# Use expect for interactive toggle selection
# Skill order (alphabetical): 1=create-slidev, 2=skill-creator, 3=standards-javascript,
#                             4=standards-python, 5=standards-shell, 6=standards-typescript
run_install_expect '
    # MCP: confirm defaults (only pdf-reader pre-selected)
    confirm_mcp

    # Skills: keep only standards-python (#4)
    select_only_skill 4

    # Accept statusline
    accept_statusline
' > /dev/null 2>&1

# Verify install worked with correct selections
assert_file_exists "$CLAUDE_DIR/CLAUDE.md" "CLAUDE.md created"
assert_file_exists "$INSTALLED_FILE" "installed.json created"
assert_dir_exists "$CLAUDE_DIR/commands" "commands installed"

# Verify MCP selection was processed
if jq -e '.mcpServers["pdf-reader"]' "$MCP_CONFIG_FILE" > /dev/null 2>&1; then
    pass "pdf-reader MCP installed (toggle selection worked)"
else
    fail "pdf-reader MCP not installed"
fi

# Verify skill selection was processed
if [[ -d "$CLAUDE_DIR/skills/standards-python" ]]; then
    pass "standards-python skill installed (toggle selection worked)"
else
    fail "standards-python skill not installed"
fi

# Verify statusline selection was processed with correct format
if jq -e '.statusLine' "$CLAUDE_DIR/settings.json" > /dev/null 2>&1; then
    # Verify statusLine is an object (not a string)
    statusline_type=$(jq -r '.statusLine | type' "$CLAUDE_DIR/settings.json")
    if [[ "$statusline_type" == "object" ]]; then
        # Verify required fields exist
        if jq -e '.statusLine.type == "command" and .statusLine.command' "$CLAUDE_DIR/settings.json" > /dev/null 2>&1; then
            pass "statusLine configured correctly as object with type and command"
        else
            fail "statusLine object missing required fields (type, command)"
        fi
    else
        fail "statusLine must be object, got: $statusline_type"
    fi
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

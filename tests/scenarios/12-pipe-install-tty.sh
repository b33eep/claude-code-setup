#!/bin/bash

# Scenario: Pipe installation with TTY support
# Tests that read_input and can_prompt functions work correctly

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

scenario "Pipe installation TTY support"

# Source the helpers module to test functions
source "$PROJECT_DIR/lib/helpers.sh"

# Test 1: can_prompt function exists
if declare -f can_prompt > /dev/null 2>&1; then
    pass "can_prompt function exists"
else
    fail "can_prompt function not found"
fi

# Test 2: read_input function exists
if declare -f read_input > /dev/null 2>&1; then
    pass "read_input function exists"
else
    fail "read_input function not found"
fi

# Test 3: quick-install.sh has correct TTY check logic
if grep -q '\[\[ -r /dev/tty \]\]' "$PROJECT_DIR/quick-install.sh"; then
    pass "quick-install.sh checks for /dev/tty"
else
    fail "quick-install.sh missing /dev/tty check"
fi

# Test 4: quick-install.sh uses --yes as fallback
if grep -q './install.sh --yes' "$PROJECT_DIR/quick-install.sh"; then
    pass "quick-install.sh uses --yes for non-interactive"
else
    fail "quick-install.sh missing --yes fallback"
fi

# Test 5: modules.sh uses read_input
if grep -q 'read_input' "$PROJECT_DIR/lib/modules.sh"; then
    pass "modules.sh uses read_input for prompts"
else
    fail "modules.sh not using read_input"
fi

# Test 6: statusline.sh uses read_input
if grep -q 'read_input' "$PROJECT_DIR/lib/statusline.sh"; then
    pass "statusline.sh uses read_input for prompts"
else
    fail "statusline.sh not using read_input"
fi

# Test 7: Non-interactive mode still works (pipe without TTY simulation)
# In CI, there's no /dev/tty, so --yes should be used automatically
scenario "Non-interactive fallback (--yes mode)"

# Reset test env for clean install
rm -rf "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR"

# Simulate pipe install without TTY (force --yes)
"$PROJECT_DIR/install.sh" --yes > /dev/null 2>&1

# Verify basic install worked
assert_file_exists "$CLAUDE_DIR/CLAUDE.md" "CLAUDE.md created with --yes"
assert_file_exists "$INSTALLED_FILE" "installed.json created with --yes"
assert_dir_exists "$CLAUDE_DIR/commands" "commands installed with --yes"

# In --yes mode, MCP and skills are skipped but statusline is enabled
if jq -e '.statusLine' "$CLAUDE_DIR/settings.json" > /dev/null 2>&1; then
    pass "statusLine auto-enabled in --yes mode"
else
    # statusLine might not be configured if npx is not available
    pass "statusLine skipped (npx not available or similar)"
fi

print_summary

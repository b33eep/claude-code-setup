#!/bin/bash

# Scenario: Status line configuration (ccstatusline)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

# Export HOME and CCSTATUS_CONFIG_DIR for ccstatusline config location
export HOME="$TEST_DIR"
export CCSTATUS_CONFIG_DIR="$TEST_DIR/.config/ccstatusline"

scenario "Status line enabled when user accepts (Y)"

# Fresh install, accept status line
printf 'none\nnone\nY\n' | "$PROJECT_DIR/install.sh" > /dev/null

# Verify Claude settings.json has statusLine as object
assert_file_exists "$CLAUDE_DIR/settings.json" "settings.json created"
assert_json_exists "$CLAUDE_DIR/settings.json" ".statusLine" "statusLine field exists"
assert_json_eq "$CLAUDE_DIR/settings.json" ".statusLine.type" "command" "statusLine type is command"
assert_json_eq "$CLAUDE_DIR/settings.json" ".statusLine.command" "npx -y ccstatusline@latest" "statusLine command correct"

# Verify ccstatusline config created
assert_file_exists "$CCSTATUS_CONFIG_DIR/settings.json" "ccstatusline config created"
assert_json_eq "$CCSTATUS_CONFIG_DIR/settings.json" ".version" "3" "ccstatusline config version is 3"

# Verify widgets configured
assert_json_exists "$CCSTATUS_CONFIG_DIR/settings.json" '.lines[0][] | select(.type == "model")' "model widget configured"
assert_json_exists "$CCSTATUS_CONFIG_DIR/settings.json" '.lines[0][] | select(.type == "context-percentage")' "context-percentage widget configured"
assert_json_exists "$CCSTATUS_CONFIG_DIR/settings.json" '.lines[0][] | select(.type == "git-branch")' "git-branch widget configured"

scenario "Status line skipped when user declines (n)"

# Reset environment
rm -rf "$CLAUDE_DIR" "$CCSTATUS_CONFIG_DIR"
mkdir -p "$CLAUDE_DIR"
echo "{\"content_version\":2,\"mcp\":[],\"skills\":[]}" > "$INSTALLED_FILE"

# Fresh install, decline status line
printf 'none\nnone\nn\n' | "$PROJECT_DIR/install.sh" > /dev/null 2>&1

# Verify settings.json either doesn't exist or has no statusLine
if [[ -f "$CLAUDE_DIR/settings.json" ]]; then
    if jq -e '.statusLine' "$CLAUDE_DIR/settings.json" > /dev/null 2>&1; then
        fail "statusLine should not be configured when declined"
    else
        pass "statusLine not configured when declined"
    fi
else
    pass "settings.json not created when status line declined"
fi

# Verify ccstatusline config not created
if [[ -f "$CCSTATUS_CONFIG_DIR/settings.json" ]]; then
    fail "ccstatusline config should not be created when declined"
else
    pass "ccstatusline config not created when declined"
fi

scenario "Status line skipped when already configured"

# Reset and pre-configure statusLine
rm -rf "$CLAUDE_DIR" "$CCSTATUS_CONFIG_DIR"
mkdir -p "$CLAUDE_DIR"
echo "{\"content_version\":2,\"mcp\":[],\"skills\":[]}" > "$INSTALLED_FILE"
echo '{"statusLine":"custom-command"}' > "$CLAUDE_DIR/settings.json"

# Run --add (should skip status line prompt)
output=$(printf 'none\nnone\n' | "$PROJECT_DIR/install.sh" --add 2>&1)

# Verify original statusLine preserved
assert_json_eq "$CLAUDE_DIR/settings.json" ".statusLine" "custom-command" "existing statusLine preserved"

# Verify output shows "already configured"
if echo "$output" | grep -q "already configured"; then
    pass "Shows 'already configured' message"
else
    fail "Should show 'already configured' message"
fi

scenario "Existing ccstatusline config preserved"

# Reset environment - don't create installed.json to avoid "existing installation" prompt
rm -rf "$CLAUDE_DIR" "$CCSTATUS_CONFIG_DIR"
mkdir -p "$CLAUDE_DIR" "$CCSTATUS_CONFIG_DIR"

# Create existing ccstatusline config with custom settings
cat > "$CCSTATUS_CONFIG_DIR/settings.json" << 'EOF'
{
  "version": 3,
  "lines": [[{"id": "custom", "type": "model"}]],
  "customSetting": true
}
EOF

# Fresh install, accept status line
printf 'none\nnone\nY\n' | "$PROJECT_DIR/install.sh" > /dev/null

# Verify Claude settings.json has statusLine
assert_json_exists "$CLAUDE_DIR/settings.json" ".statusLine" "statusLine configured"

# Verify existing ccstatusline config preserved (customSetting should still exist)
assert_json_eq "$CCSTATUS_CONFIG_DIR/settings.json" ".customSetting" "true" "existing ccstatusline config preserved"

# Verify our default config was NOT written over it
if jq -e '.lines[0][] | select(.id == "custom")' "$CCSTATUS_CONFIG_DIR/settings.json" > /dev/null 2>&1; then
    pass "Custom ccstatusline config not overwritten"
else
    fail "Custom ccstatusline config was overwritten"
fi

scenario "Default to yes with empty input (pressing Enter)"

# Reset environment
rm -rf "$CLAUDE_DIR" "$CCSTATUS_CONFIG_DIR"
mkdir -p "$CLAUDE_DIR"

# Empty input (just press Enter) - should enable status line
printf 'none\nnone\n\n' | "$PROJECT_DIR/install.sh" > /dev/null

assert_json_exists "$CLAUDE_DIR/settings.json" ".statusLine" "statusLine enabled with empty input (default Y)"
assert_file_exists "$CCSTATUS_CONFIG_DIR/settings.json" "ccstatusline config created with empty input"

scenario "Recovery from corrupted settings.json"

# Reset environment
rm -rf "$CLAUDE_DIR" "$CCSTATUS_CONFIG_DIR"
mkdir -p "$CLAUDE_DIR"

# Create corrupted settings.json
echo "this is not valid json {{{" > "$CLAUDE_DIR/settings.json"

# Install should recover and configure status line
output=$(printf 'none\nnone\nY\n' | "$PROJECT_DIR/install.sh" 2>&1)

# Verify recovery message shown
if echo "$output" | grep -q "corrupted"; then
    pass "Shows corruption warning"
else
    fail "Should show corruption warning"
fi

# Verify settings.json is now valid and has statusLine
assert_json_exists "$CLAUDE_DIR/settings.json" ".statusLine" "statusLine configured after recovery"

# Print summary
print_summary

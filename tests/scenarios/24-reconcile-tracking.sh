#!/bin/bash

# Scenario: Reconcile tracking with filesystem
# Tests that --update reconciles installed.json with what's actually installed

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

scenario "Setup: Install with tracking"

# Do a minimal install
run_install_expect '
    deselect_all_mcp
    deselect_all_skills
    decline_statusline
    decline_agent_teams
' > /dev/null

assert_file_exists "$INSTALLED_FILE" "installed.json exists"

scenario "Manually install skill without tracking"

# Copy a skill directly (simulating manual install or pre-tracking install)
mkdir -p "$CLAUDE_DIR/skills"
cp -r "$PROJECT_DIR/skills/standards-python" "$CLAUDE_DIR/skills/"

assert_dir_exists "$CLAUDE_DIR/skills/standards-python" "standards-python exists on disk"

# Verify it's NOT tracked
if jq -e '.skills[] | select(. == "standards-python")' "$INSTALLED_FILE" > /dev/null 2>&1; then
    fail "standards-python should NOT be tracked yet"
else
    pass "standards-python not tracked (as expected)"
fi

scenario "Manually configure MCP without tracking"

# Add MCP to .claude.json directly (simulating manual config)
if [ ! -f "$MCP_CONFIG_FILE" ]; then
    echo '{"mcpServers":{}}' > "$MCP_CONFIG_FILE"
fi

jq '.mcpServers["manual-mcp"] = {"type": "stdio", "command": "test"}' "$MCP_CONFIG_FILE" > "$MCP_CONFIG_FILE.tmp"
mv "$MCP_CONFIG_FILE.tmp" "$MCP_CONFIG_FILE"

assert_json_exists "$MCP_CONFIG_FILE" '.mcpServers["manual-mcp"]' "manual-mcp exists in .claude.json"

# Verify it's NOT tracked
if jq -e '.mcp[] | select(. == "manual-mcp")' "$INSTALLED_FILE" > /dev/null 2>&1; then
    fail "manual-mcp should NOT be tracked yet"
else
    pass "manual-mcp not tracked (as expected)"
fi

scenario "Run --update to trigger reconciliation"

# Lower the content version so update will run
jq '.content_version = 1' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp"
mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"

# Run update with --yes
output=$(HOME="$TEST_DIR" CLAUDE_DIR="$CLAUDE_DIR" MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
    SKIP_SKILL_DEPS=1 SKIP_EXTERNAL_PLUGINS=1 \
    "$PROJECT_DIR/install.sh" --update --yes 2>&1)

# Check that reconciliation happened
if echo "$output" | grep -q "Tracking recovered.*standards-python"; then
    pass "standards-python tracking was recovered"
else
    fail "standards-python tracking should be recovered"
fi

if echo "$output" | grep -q "Tracking recovered.*manual-mcp"; then
    pass "manual-mcp tracking was recovered"
else
    fail "manual-mcp tracking should be recovered"
fi

scenario "Verify tracking after reconciliation"

# Check skills are now tracked
assert_json_exists "$INSTALLED_FILE" '.skills[] | select(. == "standards-python")' "standards-python now tracked"

# Check MCP is now tracked
assert_json_exists "$INSTALLED_FILE" '.mcp[] | select(. == "manual-mcp")' "manual-mcp now tracked"

scenario "Second update should not show reconciliation messages"

# Lower version again
jq '.content_version = 1' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp"
mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"

# Run update again
output=$(HOME="$TEST_DIR" CLAUDE_DIR="$CLAUDE_DIR" MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
    SKIP_SKILL_DEPS=1 SKIP_EXTERNAL_PLUGINS=1 \
    "$PROJECT_DIR/install.sh" --update --yes 2>&1)

# Should NOT show reconciliation messages (already tracked)
if echo "$output" | grep -q "Tracking recovered"; then
    fail "Should not show reconciliation messages when already tracked"
else
    pass "No reconciliation messages on second update (already tracked)"
fi

scenario "Reconciliation ignores non-skill directories"

# Create a non-skill directory (no SKILL.md)
mkdir -p "$CLAUDE_DIR/skills/not-a-skill"
echo "just a file" > "$CLAUDE_DIR/skills/not-a-skill/README.md"

# Lower version and run update
jq '.content_version = 1' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp"
mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"

HOME="$TEST_DIR" CLAUDE_DIR="$CLAUDE_DIR" MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
    SKIP_SKILL_DEPS=1 SKIP_EXTERNAL_PLUGINS=1 \
    "$PROJECT_DIR/install.sh" --update --yes > /dev/null 2>&1

# Should NOT track the non-skill directory
if jq -e '.skills[] | select(. == "not-a-skill")' "$INSTALLED_FILE" > /dev/null 2>&1; then
    fail "not-a-skill should NOT be tracked (no SKILL.md)"
else
    pass "Non-skill directories are not tracked"
fi

# Print summary
print_summary

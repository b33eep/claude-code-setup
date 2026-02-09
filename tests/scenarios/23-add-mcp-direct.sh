#!/bin/bash

# Scenario: Direct MCP installation with --add-mcp

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

scenario "Install MCP directly with --add-mcp"

# First do a minimal install to have installed.json
run_install_expect '
    deselect_all_mcp
    deselect_all_skills
    decline_statusline
    decline_agent_teams
' > /dev/null

assert_file_exists "$INSTALLED_FILE" "installed.json exists"

# Install pdf-reader directly (doesn't need API key)
output=$(HOME="$TEST_DIR" CLAUDE_DIR="$CLAUDE_DIR" MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
    SKIP_SKILL_DEPS=1 "$PROJECT_DIR/install.sh" --add-mcp pdf-reader 2>&1)

assert_json_exists "$MCP_CONFIG_FILE" '.mcpServers["pdf-reader"]' "pdf-reader configured in .claude.json"
assert_json_exists "$INSTALLED_FILE" '.mcp[] | select(. == "pdf-reader")' "MCP tracked in installed.json"

# Verify output messages
if echo "$output" | grep -q "Installing MCP"; then
    pass "--add-mcp shows progress"
else
    fail "--add-mcp should show progress"
fi

if echo "$output" | grep -q "pdf-reader configured"; then
    pass "--add-mcp confirms installation"
else
    fail "--add-mcp should confirm installation"
fi

scenario "Re-install already installed MCP"

# Try to install pdf-reader again
output=$(HOME="$TEST_DIR" CLAUDE_DIR="$CLAUDE_DIR" MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
    SKIP_SKILL_DEPS=1 "$PROJECT_DIR/install.sh" --add-mcp pdf-reader 2>&1)

# Should warn but not fail
if echo "$output" | grep -q "already installed"; then
    pass "--add-mcp detects already installed MCP"
else
    fail "--add-mcp should detect already installed MCP"
fi

scenario "Install non-existent MCP"

# Try to install an MCP that doesn't exist
output=$(HOME="$TEST_DIR" CLAUDE_DIR="$CLAUDE_DIR" MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
    "$PROJECT_DIR/install.sh" --add-mcp non-existent-mcp 2>&1) || true

if echo "$output" | grep -q "not found"; then
    pass "--add-mcp reports missing MCP"
else
    fail "--add-mcp should report missing MCP"
fi

if echo "$output" | grep -q "Available MCP"; then
    pass "--add-mcp lists available MCP servers on error"
else
    fail "--add-mcp should list available MCP servers on error"
fi

scenario "--add-mcp without argument shows error"

output=$(HOME="$TEST_DIR" "$PROJECT_DIR/install.sh" --add-mcp 2>&1) || true

if echo "$output" | grep -q "requires"; then
    pass "--add-mcp without arg shows error"
else
    fail "--add-mcp without arg should show error"
fi

# Print summary
print_summary

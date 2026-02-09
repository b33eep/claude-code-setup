#!/bin/bash

# Scenario: Direct module removal with --remove-skill and --remove-mcp

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

scenario "Remove skill with --remove-skill"

# First do a minimal install then add a skill
run_install_expect '
    deselect_all_mcp
    deselect_all_skills
    decline_statusline
    decline_agent_teams
' > /dev/null

assert_file_exists "$INSTALLED_FILE" "installed.json exists"

# Install a skill to remove later
HOME="$TEST_DIR" CLAUDE_DIR="$CLAUDE_DIR" MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
    SKIP_SKILL_DEPS=1 "$PROJECT_DIR/install.sh" --add-skill standards-kotlin > /dev/null 2>&1

assert_dir_exists "$CLAUDE_DIR/skills/standards-kotlin" "standards-kotlin installed"
assert_json_exists "$INSTALLED_FILE" '.skills[] | select(. == "standards-kotlin")' "skill tracked before removal"

# Remove the skill
output=$(HOME="$TEST_DIR" CLAUDE_DIR="$CLAUDE_DIR" MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
    "$PROJECT_DIR/install.sh" --remove-skill standards-kotlin 2>&1)

# Verify skill directory is gone
if [[ -d "$CLAUDE_DIR/skills/standards-kotlin" ]]; then
    fail "skill directory should be removed"
else
    pass "skill directory removed"
fi

# Verify tracking is gone
if jq -e '.skills[] | select(. == "standards-kotlin")' "$INSTALLED_FILE" > /dev/null 2>&1; then
    fail "skill should be removed from installed.json"
else
    pass "skill removed from installed.json"
fi

# Verify output messages
if echo "$output" | grep -q "Removing Skill"; then
    pass "--remove-skill shows progress"
else
    fail "--remove-skill should show progress"
fi

if echo "$output" | grep -q "standards-kotlin removed"; then
    pass "--remove-skill confirms removal"
else
    fail "--remove-skill should confirm removal"
fi

if echo "$output" | grep -q "CLAUDE.md updated"; then
    pass "--remove-skill rebuilds CLAUDE.md"
else
    fail "--remove-skill should rebuild CLAUDE.md"
fi

# Verify removed skill is absent from CLAUDE.md content
if grep -q "standards-kotlin" "$CLAUDE_DIR/CLAUDE.md"; then
    fail "removed skill should not appear in CLAUDE.md"
else
    pass "removed skill absent from CLAUDE.md"
fi

scenario "Remove MCP with --remove-mcp"

# Install an MCP to remove later
HOME="$TEST_DIR" CLAUDE_DIR="$CLAUDE_DIR" MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
    SKIP_SKILL_DEPS=1 "$PROJECT_DIR/install.sh" --add-mcp pdf-reader > /dev/null 2>&1

assert_json_exists "$MCP_CONFIG_FILE" '.mcpServers["pdf-reader"]' "pdf-reader configured before removal"
assert_json_exists "$INSTALLED_FILE" '.mcp[] | select(. == "pdf-reader")' "MCP tracked before removal"

# Remove the MCP
output=$(HOME="$TEST_DIR" CLAUDE_DIR="$CLAUDE_DIR" MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
    "$PROJECT_DIR/install.sh" --remove-mcp pdf-reader 2>&1)

# Verify MCP is gone from config
if jq -e '.mcpServers["pdf-reader"]' "$MCP_CONFIG_FILE" > /dev/null 2>&1; then
    fail "MCP should be removed from .claude.json"
else
    pass "MCP removed from .claude.json"
fi

# Verify tracking is gone
if jq -e '.mcp[] | select(. == "pdf-reader")' "$INSTALLED_FILE" > /dev/null 2>&1; then
    fail "MCP should be removed from installed.json"
else
    pass "MCP removed from installed.json"
fi

# Verify output messages
if echo "$output" | grep -q "Removing MCP"; then
    pass "--remove-mcp shows progress"
else
    fail "--remove-mcp should show progress"
fi

if echo "$output" | grep -q "pdf-reader removed"; then
    pass "--remove-mcp confirms removal"
else
    fail "--remove-mcp should confirm removal"
fi

# Verify removed MCP is absent from CLAUDE.md content
if grep -q "pdf-reader" "$CLAUDE_DIR/CLAUDE.md"; then
    fail "removed MCP should not appear in CLAUDE.md"
else
    pass "removed MCP absent from CLAUDE.md"
fi

scenario "Remove non-existent skill"

output=$(HOME="$TEST_DIR" CLAUDE_DIR="$CLAUDE_DIR" MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
    "$PROJECT_DIR/install.sh" --remove-skill nonexistent 2>&1) || true

if echo "$output" | grep -q "not installed"; then
    pass "--remove-skill reports non-installed skill"
else
    fail "--remove-skill should report non-installed skill"
fi

scenario "Remove non-existent MCP"

output=$(HOME="$TEST_DIR" CLAUDE_DIR="$CLAUDE_DIR" MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
    "$PROJECT_DIR/install.sh" --remove-mcp nonexistent 2>&1) || true

if echo "$output" | grep -q "not installed"; then
    pass "--remove-mcp reports non-installed MCP"
else
    fail "--remove-mcp should report non-installed MCP"
fi

scenario "--remove-skill without argument shows error"

output=$(HOME="$TEST_DIR" "$PROJECT_DIR/install.sh" --remove-skill 2>&1) || true

if echo "$output" | grep -q "requires"; then
    pass "--remove-skill without arg shows error"
else
    fail "--remove-skill without arg should show error"
fi

scenario "--remove-mcp without argument shows error"

output=$(HOME="$TEST_DIR" "$PROJECT_DIR/install.sh" --remove-mcp 2>&1) || true

if echo "$output" | grep -q "requires"; then
    pass "--remove-mcp without arg shows error"
else
    fail "--remove-mcp without arg should show error"
fi

# Print summary
print_summary

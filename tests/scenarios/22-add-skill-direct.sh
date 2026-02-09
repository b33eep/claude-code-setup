#!/bin/bash

# Scenario: Direct skill installation with --add-skill

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

scenario "Install skill directly with --add-skill"

# First do a minimal install to have installed.json
run_install_expect '
    deselect_all_mcp
    deselect_all_skills
    decline_statusline
    decline_agent_teams
' > /dev/null

assert_file_exists "$INSTALLED_FILE" "installed.json exists"

# Install standards-kotlin directly
output=$(HOME="$TEST_DIR" CLAUDE_DIR="$CLAUDE_DIR" MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
    SKIP_SKILL_DEPS=1 "$PROJECT_DIR/install.sh" --add-skill standards-kotlin 2>&1)

assert_dir_exists "$CLAUDE_DIR/skills/standards-kotlin" "standards-kotlin installed"
assert_json_exists "$INSTALLED_FILE" '.skills[] | select(. == "standards-kotlin")' "skill tracked in installed.json"
assert_file_exists "$CLAUDE_DIR/skills/standards-kotlin/SKILL.md" "SKILL.md exists"

# Verify output messages
if echo "$output" | grep -q "Installing Skill"; then
    pass "--add-skill shows progress"
else
    fail "--add-skill should show progress"
fi

if echo "$output" | grep -q "standards-kotlin installed"; then
    pass "--add-skill confirms installation"
else
    fail "--add-skill should confirm installation"
fi

scenario "Install second skill directly"

# Install standards-gradle
HOME="$TEST_DIR" CLAUDE_DIR="$CLAUDE_DIR" MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
    SKIP_SKILL_DEPS=1 "$PROJECT_DIR/install.sh" --add-skill standards-gradle > /dev/null 2>&1

assert_dir_exists "$CLAUDE_DIR/skills/standards-gradle" "standards-gradle installed"
assert_json_exists "$INSTALLED_FILE" '.skills[] | select(. == "standards-gradle")' "standards-gradle tracked"

# Verify both skills are tracked
skill_count=$(jq '.skills | length' "$INSTALLED_FILE")
if [ "$skill_count" -ge 2 ]; then
    pass "Multiple skills tracked ($skill_count skills)"
else
    fail "Should have at least 2 skills tracked (got $skill_count)"
fi

scenario "Re-install already installed skill"

# Try to install standards-kotlin again
output=$(HOME="$TEST_DIR" CLAUDE_DIR="$CLAUDE_DIR" MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
    SKIP_SKILL_DEPS=1 "$PROJECT_DIR/install.sh" --add-skill standards-kotlin 2>&1)

# Should warn but not fail
if echo "$output" | grep -q "already installed"; then
    pass "--add-skill detects already installed skill"
else
    fail "--add-skill should detect already installed skill"
fi

scenario "Install non-existent skill"

# Try to install a skill that doesn't exist
output=$(HOME="$TEST_DIR" CLAUDE_DIR="$CLAUDE_DIR" MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
    "$PROJECT_DIR/install.sh" --add-skill non-existent-skill 2>&1) || true

if echo "$output" | grep -q "not found"; then
    pass "--add-skill reports missing skill"
else
    fail "--add-skill should report missing skill"
fi

if echo "$output" | grep -q "Available skills"; then
    pass "--add-skill lists available skills on error"
else
    fail "--add-skill should list available skills on error"
fi

scenario "--add-skill without argument shows error"

output=$(HOME="$TEST_DIR" "$PROJECT_DIR/install.sh" --add-skill 2>&1) || true

if echo "$output" | grep -q "requires"; then
    pass "--add-skill without arg shows error"
else
    fail "--add-skill without arg should show error"
fi

# Print summary
print_summary

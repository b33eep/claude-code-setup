#!/bin/bash

# Scenario: /claude-code-setup command structure (3-phase flow)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

scenario "claude-code-setup.md command exists"

assert_file_exists "$PROJECT_DIR/commands/claude-code-setup.md" "claude-code-setup.md exists"

scenario "Command has 3-phase structure"

assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "Phase 1" "Has Phase 1 (Discovery)"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "Phase 2" "Has Phase 2 (Present + Ask)"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "Phase 3" "Has Phase 3 (Execute)"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "setup-status.sh" "Uses setup-status.sh discovery script"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "AskUserQuestion" "Uses AskUserQuestion for user input"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "multiSelect" "Supports multi-select"

scenario "Command has discovery phase"

assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "git clone" "Has clone instruction"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "installed.json" "References installed.json"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "content_version" "References content_version"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "templates/VERSION" "References templates/VERSION"

scenario "Command has status presentation"

assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "up-to-date" "Has up-to-date message"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "Modules available to install" "Shows available modules output"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "External Plugins" "Shows External Plugins in status"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "CHANGELOG" "References CHANGELOG for upgrade notes"

scenario "Command has execution chains"

assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "install.sh --update" "Runs install.sh --update"

# Use grep -F for fixed string match (avoids -- being interpreted as option)
if grep -qF -- "--update --yes" "$PROJECT_DIR/commands/claude-code-setup.md"; then
    pass "Uses --yes flag for non-interactive update"
else
    fail "Should use --yes flag for non-interactive update"
fi

assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "install.sh --add-skill" "Can install skills via --add-skill"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "install.sh --add-mcp" "Can install MCP via --add-mcp"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "install.sh --remove-skill" "Can remove skills via --remove-skill"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "install.sh --remove-mcp" "Can remove MCP via --remove-mcp"

scenario "Command has custom repo support"

assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "custom_version" "Checks custom_version"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "custom.update_available" "Checks custom update status from JSON"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "Upgrade custom" "Has upgrade custom option"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "not configured" "Has no-custom-repo message"

scenario "Command has Agent Teams support"

assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "agent_teams.enabled" "Checks Agent Teams status from JSON"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "Enable Agent Teams" "Has Enable Agent Teams option"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" "References Agent Teams env var"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "Agent Teams: enabled" "Has enabled status example"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "Agent Teams: not configured" "Has not-configured status example"

scenario "Command has external plugins support"

assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "external-plugins.json" "References external-plugins.json"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "claude plugin marketplace" "Has marketplace add instruction"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "claude plugin install" "Has plugin install instruction"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "Restart Claude Code" "Has restart hint"

scenario "Command has MCP API key handling"

assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "requiresApiKey" "Checks for API key requirement"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "YOUR_API_KEY_HERE" "Uses placeholder for API keys"

scenario "Command has cleanup and constraints"

assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "; rm -rf" "Cleanup uses ; separator (not &&)"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "0 Bash calls" "Phase 2 specifies zero Bash calls"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "claude plugin remove" "Has plugin remove instruction"

scenario "Command has error handling"

assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "Manual upgrade" "Has manual fallback"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "not_installed" "Handles not-installed error"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "rm -rf" "Cleans up temp dir"

# Print summary
print_summary

#!/bin/bash

# Scenario: Agent Teams configuration toggle

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

scenario "Agent Teams enabled when user accepts (y)"

# Fresh install, accept Agent Teams
run_install_expect '
    deselect_all_mcp
    deselect_all_skills
    decline_statusline
    accept_agent_teams
' > /dev/null

# Verify settings.json has env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS
assert_file_exists "$CLAUDE_DIR/settings.json" "settings.json created"
assert_json_eq "$CLAUDE_DIR/settings.json" ".env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" "1" "Agent Teams env var set to 1"

scenario "Agent Teams skipped when user declines (n)"

# Reset environment
rm -rf "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR"
echo "{\"content_version\":2,\"mcp\":[],\"skills\":[]}" > "$INSTALLED_FILE"

run_install_expect '
    deselect_all_mcp
    deselect_all_skills
    decline_statusline
    decline_agent_teams
' > /dev/null 2>&1

# Verify env var is NOT set
if [[ -f "$CLAUDE_DIR/settings.json" ]]; then
    if jq -e '.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS' "$CLAUDE_DIR/settings.json" > /dev/null 2>&1; then
        fail "Agent Teams should not be configured when declined"
    else
        pass "Agent Teams not configured when declined"
    fi
else
    pass "Agent Teams not configured (no settings.json)"
fi

scenario "Agent Teams skipped when already configured"

# Reset and pre-configure Agent Teams
rm -rf "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR"
echo "{\"content_version\":2,\"mcp\":[],\"skills\":[]}" > "$INSTALLED_FILE"
echo '{"env":{"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS":"1"}}' > "$CLAUDE_DIR/settings.json"

# Run --add (should skip Agent Teams prompt)
output=$(run_add_expect '
    deselect_all_mcp
    deselect_all_skills
    decline_statusline
' 2>&1)

# Verify Agent Teams still configured
assert_json_eq "$CLAUDE_DIR/settings.json" ".env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" "1" "Agent Teams preserved"

# Verify output shows "already configured"
if echo "$output" | grep -q "Agent Teams already configured"; then
    pass "Shows 'already configured' message"
else
    fail "Should show 'already configured' message"
fi

scenario "Agent Teams skipped in --yes mode"

# Reset environment
rm -rf "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR"

# Run with --yes (Agent Teams should be skipped since experimental)
"$PROJECT_DIR/install.sh" --yes > /dev/null 2>&1

# Verify Agent Teams NOT configured
if [[ -f "$CLAUDE_DIR/settings.json" ]]; then
    if jq -e '.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS' "$CLAUDE_DIR/settings.json" > /dev/null 2>&1; then
        fail "Agent Teams should be skipped in --yes mode"
    else
        pass "Agent Teams skipped in --yes mode"
    fi
else
    pass "Agent Teams skipped in --yes mode (no settings.json)"
fi

scenario "Default to no with empty input (pressing Enter)"

# Reset environment
rm -rf "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR"

# Empty input (just press Enter) - should NOT enable Agent Teams (default is N)
run_install_expect '
    deselect_all_mcp
    deselect_all_skills
    decline_statusline

    # Press Enter (default is N)
    expect {Enable Agent Teams} { send "\r" }
' > /dev/null

if [[ -f "$CLAUDE_DIR/settings.json" ]]; then
    if jq -e '.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS' "$CLAUDE_DIR/settings.json" > /dev/null 2>&1; then
        fail "Agent Teams should not be enabled with empty input (default N)"
    else
        pass "Agent Teams not enabled with empty input (default N)"
    fi
else
    pass "Agent Teams not enabled with empty input (default N)"
fi

scenario "Agent Teams enabled via update (pre-Agent-Teams user)"

# Reset environment — simulate a pre-Agent-Teams installation
rm -rf "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR"

# Install without Agent Teams first
run_install_expect '
    deselect_all_mcp
    deselect_all_skills
    decline_statusline
    decline_agent_teams
' > /dev/null

# Verify Agent Teams is NOT configured after install
if [[ -f "$CLAUDE_DIR/settings.json" ]] && jq -e '.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS' "$CLAUDE_DIR/settings.json" > /dev/null 2>&1; then
    fail "Agent Teams should not be configured before update"
else
    pass "Agent Teams not configured before update"
fi

# Simulate outdated version to trigger update
jq '.content_version = 0' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp" && mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"

# Run update, accept Agent Teams this time
run_update_expect '
    expect {
        {Proceed?} { send "y\r" }
        timeout { puts "TIMEOUT at update confirm"; exit 1 }
    }
    accept_agent_teams
    expect {
        {Install new modules?} { send "n\r" }
        timeout { puts "TIMEOUT at new modules"; exit 1 }
    }
' > /dev/null

# Verify Agent Teams is now configured
assert_json_eq "$CLAUDE_DIR/settings.json" ".env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" "1" "Agent Teams enabled after update"

scenario "Agent Teams coexists with other settings"

# Reset and pre-configure statusline
rm -rf "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR"

# Install with statusline enabled AND Agent Teams enabled
run_install_expect '
    deselect_all_mcp
    deselect_all_skills
    accept_statusline
    accept_agent_teams
' > /dev/null

# Verify both statusline and Agent Teams are configured
assert_json_exists "$CLAUDE_DIR/settings.json" ".statusLine" "statusLine still configured"
assert_json_eq "$CLAUDE_DIR/settings.json" ".env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" "1" "Agent Teams configured alongside statusline"

# Print summary
print_summary

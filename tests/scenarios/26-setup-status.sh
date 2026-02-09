#!/bin/bash

# Scenario: Discovery script (setup-status.sh) outputs valid JSON status

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

# Helper: run setup-status.sh in test environment
run_setup_status() {
    HOME="$TEST_DIR" \
    CLAUDE_DIR="$CLAUDE_DIR" \
    MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
        "$PROJECT_DIR/lib/setup-status.sh" 2>/dev/null
}

# ============================================
# SCENARIO: No installed.json → error output
# ============================================

scenario "No installed.json outputs error"

output=$(run_setup_status)

# Must be valid JSON
if echo "$output" | jq . > /dev/null 2>&1; then
    pass "Output is valid JSON"
else
    fail "Output should be valid JSON (got: $output)"
fi

# Must contain error field
if echo "$output" | jq -e '.error == "not_installed"' > /dev/null 2>&1; then
    pass "Error is 'not_installed'"
else
    fail "Should output error: not_installed"
fi

# ============================================
# SCENARIO: After minimal install
# ============================================

scenario "Setup status after minimal install"

# Do a minimal install (no MCP, no skills)
run_install_expect '
    deselect_all_mcp
    deselect_all_skills
    decline_statusline
    decline_agent_teams
' > /dev/null

assert_file_exists "$INSTALLED_FILE" "installed.json exists after install"

# Run setup-status.sh
output=$(run_setup_status)

# Must be valid JSON
if echo "$output" | jq . > /dev/null 2>&1; then
    pass "Output is valid JSON after install"
else
    fail "Output should be valid JSON after install (got: $output)"
fi

# ============================================
# SCENARIO: Base version checks
# ============================================

scenario "Base version fields"

available_version=$(cat "$PROJECT_DIR/templates/VERSION")
installed_version=$(jq -r '.content_version' "$INSTALLED_FILE")

# .base.installed matches installed.json
actual_installed=$(echo "$output" | jq '.base.installed')
if [[ "$actual_installed" = "$installed_version" ]]; then
    pass ".base.installed matches installed.json ($installed_version)"
else
    fail ".base.installed should be $installed_version (got: $actual_installed)"
fi

# .base.available matches templates/VERSION
actual_available=$(echo "$output" | jq '.base.available')
if [[ "$actual_available" = "$available_version" ]]; then
    pass ".base.available matches templates/VERSION ($available_version)"
else
    fail ".base.available should be $available_version (got: $actual_available)"
fi

# .base.update_available should be false (same version)
actual_update=$(echo "$output" | jq '.base.update_available')
if [[ "$actual_update" = "false" ]]; then
    pass ".base.update_available is false (same version)"
else
    fail ".base.update_available should be false (got: $actual_update)"
fi

# ============================================
# SCENARIO: Update available detection
# ============================================

scenario "Detects update available"

# Artificially lower the installed version
jq '.content_version = 1' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp" && mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"

output=$(run_setup_status)

actual_update=$(echo "$output" | jq '.base.update_available')
if [[ "$actual_update" = "true" ]]; then
    pass ".base.update_available is true when installed < available"
else
    fail ".base.update_available should be true (got: $actual_update)"
fi

actual_installed=$(echo "$output" | jq '.base.installed')
if [[ "$actual_installed" = "1" ]]; then
    pass ".base.installed reflects lowered version (1)"
else
    fail ".base.installed should be 1 (got: $actual_installed)"
fi

# Restore version for subsequent tests
jq --argjson v "$available_version" '.content_version = $v' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp" && mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"

# ============================================
# SCENARIO: Installed modules
# ============================================

scenario "Installed modules (empty after minimal install)"

output=$(run_setup_status)

installed_skills_count=$(echo "$output" | jq '.installed_modules.skills | length')
if [[ "$installed_skills_count" = "0" ]]; then
    pass ".installed_modules.skills is empty (no skills installed)"
else
    fail ".installed_modules.skills should be empty (got $installed_skills_count)"
fi

installed_mcp_count=$(echo "$output" | jq '.installed_modules.mcp | length')
if [[ "$installed_mcp_count" = "0" ]]; then
    pass ".installed_modules.mcp is empty (no MCP installed)"
else
    fail ".installed_modules.mcp should be empty (got $installed_mcp_count)"
fi

# ============================================
# SCENARIO: New modules detection
# ============================================

scenario "New + installed modules equal repo total"

# Count available skills in the repo
repo_skills_count=0
for d in "$PROJECT_DIR/skills/"*/; do
    [[ -d "$d" ]] && repo_skills_count=$((repo_skills_count + 1))
done
new_skills_count=$(echo "$output" | jq '.new_modules.skills | length')
installed_skills_count=$(echo "$output" | jq '.installed_modules.skills | length')
total_skills=$((new_skills_count + installed_skills_count))
if [[ "$total_skills" = "$repo_skills_count" ]]; then
    pass "new + installed skills = repo total ($repo_skills_count)"
else
    fail "new ($new_skills_count) + installed ($installed_skills_count) should equal $repo_skills_count (got: $total_skills)"
fi

# Count available MCP in the repo
repo_mcp_count=0
for f in "$PROJECT_DIR/mcp/"*.json; do
    [[ -f "$f" ]] && repo_mcp_count=$((repo_mcp_count + 1))
done
new_mcp_count=$(echo "$output" | jq '.new_modules.mcp | length')
installed_mcp_count=$(echo "$output" | jq '.installed_modules.mcp | length')
total_mcp=$((new_mcp_count + installed_mcp_count))
if [[ "$total_mcp" = "$repo_mcp_count" ]]; then
    pass "new + installed MCP = repo total ($repo_mcp_count)"
else
    fail "new ($new_mcp_count) + installed ($installed_mcp_count) should equal $repo_mcp_count (got: $total_mcp)"
fi

# ============================================
# SCENARIO: After installing a skill
# ============================================

scenario "Reflects installed skill"

# Install one skill directly
HOME="$TEST_DIR" CLAUDE_DIR="$CLAUDE_DIR" MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
    SKIP_SKILL_DEPS=1 "$PROJECT_DIR/install.sh" --add-skill standards-python > /dev/null 2>&1

output=$(run_setup_status)

# standards-python should be in installed_modules.skills
if echo "$output" | jq -e '.installed_modules.skills | index("standards-python")' > /dev/null 2>&1; then
    pass "standards-python in .installed_modules.skills"
else
    fail "standards-python should be in .installed_modules.skills"
fi

# standards-python should NOT be in new_modules.skills
if echo "$output" | jq -e '.new_modules.skills | index("standards-python")' > /dev/null 2>&1; then
    fail "standards-python should NOT be in .new_modules.skills"
else
    pass "standards-python not in .new_modules.skills"
fi

# new + installed should still equal repo total
actual_new=$(echo "$output" | jq '.new_modules.skills | length')
actual_installed=$(echo "$output" | jq '.installed_modules.skills | length')
actual_total=$((actual_new + actual_installed))
if [[ "$actual_total" = "$repo_skills_count" ]]; then
    pass "new + installed skills still = repo total after add ($repo_skills_count)"
else
    fail "new ($actual_new) + installed ($actual_installed) should equal $repo_skills_count (got: $actual_total)"
fi

# ============================================
# SCENARIO: After installing an MCP
# ============================================

scenario "Reflects installed MCP"

HOME="$TEST_DIR" CLAUDE_DIR="$CLAUDE_DIR" MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
    "$PROJECT_DIR/install.sh" --add-mcp pdf-reader > /dev/null 2>&1

output=$(run_setup_status)

if echo "$output" | jq -e '.installed_modules.mcp | index("pdf-reader")' > /dev/null 2>&1; then
    pass "pdf-reader in .installed_modules.mcp"
else
    fail "pdf-reader should be in .installed_modules.mcp"
fi

if echo "$output" | jq -e '.new_modules.mcp | index("pdf-reader")' > /dev/null 2>&1; then
    fail "pdf-reader should NOT be in .new_modules.mcp"
else
    pass "pdf-reader not in .new_modules.mcp"
fi

# ============================================
# SCENARIO: Agent Teams status
# ============================================

scenario "Agent Teams disabled by default"

output=$(run_setup_status)

actual_teams=$(echo "$output" | jq '.agent_teams.enabled')
if [[ "$actual_teams" = "false" ]]; then
    pass ".agent_teams.enabled is false"
else
    fail ".agent_teams.enabled should be false (got: $actual_teams)"
fi

scenario "Agent Teams enabled"

# Enable agent teams in settings.json
mkdir -p "$CLAUDE_DIR"
echo '{}' > "$CLAUDE_DIR/settings.json"
jq '.env = (.env // {}) | .env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"' \
    "$CLAUDE_DIR/settings.json" > "$CLAUDE_DIR/settings.json.tmp" && \
    mv "$CLAUDE_DIR/settings.json.tmp" "$CLAUDE_DIR/settings.json"

output=$(run_setup_status)

actual_teams=$(echo "$output" | jq '.agent_teams.enabled')
if [[ "$actual_teams" = "true" ]]; then
    pass ".agent_teams.enabled is true"
else
    fail ".agent_teams.enabled should be true (got: $actual_teams)"
fi

# ============================================
# SCENARIO: Custom repo not configured
# ============================================

scenario "Custom repo not configured"

output=$(run_setup_status)

actual_custom=$(echo "$output" | jq '.custom.configured')
if [[ "$actual_custom" = "false" ]]; then
    pass ".custom.configured is false"
else
    fail ".custom.configured should be false (got: $actual_custom)"
fi

# ============================================
# SCENARIO: temp_dir in output
# ============================================

scenario "temp_dir in output"

output=$(run_setup_status)

actual_temp=$(echo "$output" | jq -r '.temp_dir')
if [[ "$actual_temp" = "$PROJECT_DIR" ]]; then
    pass ".temp_dir matches SCRIPT_DIR parent ($PROJECT_DIR)"
else
    fail ".temp_dir should be $PROJECT_DIR (got: $actual_temp)"
fi

# ============================================
# SCENARIO: stdout is valid JSON (no stderr leakage)
# ============================================

scenario "No stderr leakage to stdout"

# Run and capture stdout only (stderr goes to /dev/null)
stdout_output=$(run_setup_status)

# Validate entire stdout is valid JSON
if echo "$stdout_output" | jq . > /dev/null 2>&1; then
    pass "stdout is clean JSON (no stderr leakage)"
else
    fail "stdout should be valid JSON without stderr content"
fi

# Verify output has all expected top-level keys
for key in temp_dir base custom new_modules installed_modules agent_teams; do
    if echo "$stdout_output" | jq -e "has(\"$key\")" > /dev/null 2>&1; then
        pass "Has required key: $key"
    else
        fail "Missing required key: $key"
    fi
done

# ============================================
# SCENARIO: Plugins discovery
# ============================================

scenario "Plugins discovery"

output=$(run_setup_status)

# Should have new plugins listed (none installed)
new_plugins_count=$(echo "$output" | jq '.new_modules.plugins | length')
if [[ "$new_plugins_count" -gt 0 ]]; then
    pass ".new_modules.plugins has entries ($new_plugins_count)"
else
    fail ".new_modules.plugins should have entries (got: $new_plugins_count)"
fi

# Check that plugin IDs contain @ separator (id@marketplace format)
first_plugin=$(echo "$output" | jq -r '.new_modules.plugins[0]')
if [[ "$first_plugin" == *"@"* ]]; then
    pass "Plugin IDs use id@marketplace format ($first_plugin)"
else
    fail "Plugin IDs should use id@marketplace format (got: $first_plugin)"
fi

# Print summary
print_summary

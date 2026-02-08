#!/bin/bash

# Scenario: Update notification hook

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

scenario "Hook script existence"

assert_file_exists "$PROJECT_DIR/hooks/check-update.sh" "check-update.sh exists in repo"

scenario "No installed.json - silent exit"

# Ensure no installed.json exists
rm -f "$INSTALLED_FILE"

output=$(HOME="$TEST_DIR" bash "$PROJECT_DIR/hooks/check-update.sh" 2>&1) || true
if [[ -z "$output" ]]; then
    pass "No installed.json -> no output"
else
    fail "No installed.json -> no output (got: $output)"
fi

scenario "Base up-to-date - no notification"

# Set up installed.json with very high version (always up to date)
mkdir -p "$CLAUDE_DIR"
echo '{"content_version": 9999}' > "$INSTALLED_FILE"

output=$(HOME="$TEST_DIR" bash "$PROJECT_DIR/hooks/check-update.sh" 2>&1) || true
if [[ -z "$output" ]]; then
    pass "Base up-to-date -> no output"
else
    fail "Base up-to-date -> no output (got: $output)"
fi

scenario "Base update available - shows notification"

# Set version to very low (update always available)
echo '{"content_version": 1}' > "$INSTALLED_FILE"

# Mock curl to return high version
mkdir -p "$TEST_DIR/bin"
cat > "$TEST_DIR/bin/curl" << 'MOCKEOF'
#!/bin/bash
# Mock curl - return version 9999
echo "9999"
MOCKEOF
chmod +x "$TEST_DIR/bin/curl"

output=$(PATH="$TEST_DIR/bin:$PATH" HOME="$TEST_DIR" bash "$PROJECT_DIR/hooks/check-update.sh" 2>&1) || true
if [[ "$output" == *"Update available"* && "$output" == *"v1"* && "$output" == *"v9999"* ]]; then
    pass "Base update available -> shows hint with versions"
else
    fail "Base update available -> shows hint (got: $output)"
fi

scenario "Custom repo update available - shows notification"

# Reset base to up-to-date, set custom_version to 1
echo '{"content_version": 9999, "custom_version": 1}' > "$INSTALLED_FILE"

# Create mock custom repo with .git directory
mkdir -p "$CLAUDE_DIR/custom/.git"

# Mock git to return higher VERSION from remote
cat > "$TEST_DIR/bin/git" << 'MOCKEOF'
#!/bin/bash
if [[ "$*" == *"fetch"* ]]; then
    exit 0
elif [[ "$*" == *"show origin/main:VERSION"* ]]; then
    echo "99"
elif [[ "$*" == *"show origin/master:VERSION"* ]]; then
    echo "99"
fi
MOCKEOF
chmod +x "$TEST_DIR/bin/git"

output=$(PATH="$TEST_DIR/bin:$PATH" HOME="$TEST_DIR" bash "$PROJECT_DIR/hooks/check-update.sh" 2>&1) || true
if [[ "$output" == *"Custom"* && "$output" == *"update available"* && "$output" == *"v1"* && "$output" == *"v99"* ]]; then
    pass "Custom update available -> shows hint with versions"
else
    fail "Custom update available -> shows hint (got: $output)"
fi

scenario "Custom repo up-to-date - no notification"

# Set custom_version same as remote will return
echo '{"content_version": 9999, "custom_version": 99}' > "$INSTALLED_FILE"

# Mock git to return same VERSION
cat > "$TEST_DIR/bin/git" << 'MOCKEOF'
#!/bin/bash
if [[ "$*" == *"fetch"* ]]; then
    exit 0
elif [[ "$*" == *"show origin/main:VERSION"* ]]; then
    echo "99"
elif [[ "$*" == *"show origin/master:VERSION"* ]]; then
    echo "99"
fi
MOCKEOF
chmod +x "$TEST_DIR/bin/git"

output=$(PATH="$TEST_DIR/bin:$PATH" HOME="$TEST_DIR" bash "$PROJECT_DIR/hooks/check-update.sh" 2>&1) || true
if [[ -z "$output" ]]; then
    pass "Custom up-to-date -> no output"
else
    fail "Custom up-to-date -> no output (got: $output)"
fi

scenario "Network failure - silent (no crash)"

# Mock curl to fail
cat > "$TEST_DIR/bin/curl" << 'MOCKEOF'
#!/bin/bash
exit 1
MOCKEOF
chmod +x "$TEST_DIR/bin/curl"

# Mock git to fail
cat > "$TEST_DIR/bin/git" << 'MOCKEOF'
#!/bin/bash
exit 1
MOCKEOF
chmod +x "$TEST_DIR/bin/git"

# Reset to trigger version check
echo '{"content_version": 1}' > "$INSTALLED_FILE"

output=$(PATH="$TEST_DIR/bin:$PATH" HOME="$TEST_DIR" bash "$PROJECT_DIR/hooks/check-update.sh" 2>&1) || true
exit_code=$?
if [[ $exit_code -eq 0 && -z "$output" ]]; then
    pass "Network failure -> silent exit (no crash)"
else
    fail "Network failure -> silent exit (exit=$exit_code, output: $output)"
fi

scenario "Hook installation via installer"

# Run installer and verify hook is configured
run_install_expect '
    confirm_mcp
    confirm_skills
    decline_statusline
    decline_agent_teams
' > /dev/null

assert_file_exists "$CLAUDE_DIR/hooks/check-update.sh" "Hook script installed to ~/.claude/hooks/"
assert_json_exists "$CLAUDE_DIR/settings.json" '.hooks.SessionStart' "SessionStart hook configured in settings.json"

# Check hook command points to correct script
hook_command=$(jq -r '.hooks.SessionStart[0].hooks[0].command' "$CLAUDE_DIR/settings.json" 2>/dev/null) || true
if [[ "$hook_command" == *"check-update.sh"* ]]; then
    pass "Hook command points to check-update.sh"
else
    fail "Hook command should point to check-update.sh (got: $hook_command)"
fi

# Check matcher is correct
matcher=$(jq -r '.hooks.SessionStart[0].matcher' "$CLAUDE_DIR/settings.json" 2>/dev/null) || true
if [[ "$matcher" == "startup|clear" ]]; then
    pass "Hook matcher is 'startup|clear'"
else
    fail "Hook matcher should be 'startup|clear' (got: $matcher)"
fi

scenario "Hook installation via update (pre-v33 user)"

# Simulate pre-v33 installation: remove hooks from settings.json and delete hook script
rm -f "$CLAUDE_DIR/hooks/check-update.sh"
rmdir "$CLAUDE_DIR/hooks" 2>/dev/null || true
jq 'del(.hooks)' "$CLAUDE_DIR/settings.json" > "$CLAUDE_DIR/settings.json.tmp"
mv "$CLAUDE_DIR/settings.json.tmp" "$CLAUDE_DIR/settings.json"

# Set old version to trigger update
jq '.content_version = 0' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp"
mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"

# Verify hooks are gone before update
if [[ -f "$CLAUDE_DIR/hooks/check-update.sh" ]]; then
    fail "Hook script should not exist before update test"
fi
if jq -e '.hooks.SessionStart' "$CLAUDE_DIR/settings.json" > /dev/null 2>&1; then
    fail "SessionStart hook should not exist before update test"
fi
pass "Pre-v33 state simulated (no hooks)"

# Run update
run_update_expect '
    confirm_update
    decline_agent_teams
' > /dev/null

# Verify hooks are now installed
assert_file_exists "$CLAUDE_DIR/hooks/check-update.sh" "Hook script installed during update"
assert_json_exists "$CLAUDE_DIR/settings.json" '.hooks.SessionStart' "SessionStart hook configured during update"

# Print summary
print_summary

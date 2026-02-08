#!/bin/bash

# Scenario: /with-advisor command structure
# Note: This tests the command file structure. Full E2E test would require
# Claude to execute the command with Agent Teams, which is tested manually.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

scenario "with-advisor.md command exists"

assert_file_exists "$PROJECT_DIR/commands/with-advisor.md" "with-advisor.md exists"

scenario "Command has task complexity assessment"

assert_file_contains "$PROJECT_DIR/commands/with-advisor.md" "overhead" "Uses overhead-vs-benefit principle"
assert_file_contains "$PROJECT_DIR/commands/with-advisor.md" "too simple" "Has simple task rejection"

scenario "Command has advisor selection"

assert_file_contains "$PROJECT_DIR/commands/with-advisor.md" "Max 2 advisors" "Limits to max 2 advisors"
assert_file_contains "$PROJECT_DIR/commands/with-advisor.md" "problem.*being solved" "Frames advisors around the problem"

scenario "Command has spawn prompt with /catchup onboarding"

assert_file_contains "$PROJECT_DIR/commands/with-advisor.md" "/catchup" "Advisor runs /catchup"
assert_file_contains "$PROJECT_DIR/commands/with-advisor.md" "Do NOT write or edit code" "Advisor is read-only"
assert_file_contains "$PROJECT_DIR/commands/with-advisor.md" "SendMessage" "Advisor uses SendMessage"

scenario "Command has progress update mechanism"

assert_file_contains "$PROJECT_DIR/commands/with-advisor.md" "progress update" "Has progress update instructions"
assert_file_contains "$PROJECT_DIR/commands/with-advisor.md" "git diff" "Advisors review via git diff"

scenario "Command has error handling"

assert_file_contains "$PROJECT_DIR/commands/with-advisor.md" "spawning fails" "Has spawn failure handling"
assert_file_contains "$PROJECT_DIR/commands/with-advisor.md" "already exists" "Handles duplicate team"
assert_file_contains "$PROJECT_DIR/commands/with-advisor.md" "shutdown_request" "Has shutdown mechanism"

scenario "Command is installed during fresh install"

run_install_expect '
    deselect_all_mcp
    deselect_all_skills
    decline_statusline
    decline_agent_teams
' > /dev/null

assert_file_exists "$CLAUDE_DIR/commands/with-advisor.md" "with-advisor.md installed"

# Verify installed file matches source
expected=$(sha256_file "$PROJECT_DIR/commands/with-advisor.md")
actual=$(sha256_file "$CLAUDE_DIR/commands/with-advisor.md")
if [[ "$expected" = "$actual" ]]; then
    pass "Installed with-advisor.md matches source"
else
    fail "Installed with-advisor.md does not match source"
fi

# Print summary
print_summary

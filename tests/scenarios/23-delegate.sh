#!/bin/bash

# Scenario: /delegate command structure
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

scenario "delegate.md command exists"

assert_file_exists "$PROJECT_DIR/commands/delegate.md" "delegate.md exists"

scenario "Command has task fitness assessment"

assert_file_contains "$PROJECT_DIR/commands/delegate.md" "with-advisor instead" "Suggests /with-advisor for wrong fit"
assert_file_contains "$PROJECT_DIR/commands/delegate.md" "continuous input" "Identifies interactive tasks"

scenario "Command has task type classification"

assert_file_contains "$PROJECT_DIR/commands/delegate.md" "git worktree" "Uses git worktree for write tasks"
assert_file_contains "$PROJECT_DIR/commands/delegate.md" "Read-only" "Has read-only task type"
assert_file_contains "$PROJECT_DIR/commands/delegate.md" "/tmp" "Uses /tmp for read-only tasks"

scenario "Command has spawn prompt with /catchup onboarding"

assert_file_contains "$PROJECT_DIR/commands/delegate.md" "/catchup" "Delegate runs /catchup"
assert_file_contains "$PROJECT_DIR/commands/delegate.md" "SendMessage" "Delegate uses SendMessage"
assert_file_contains "$PROJECT_DIR/commands/delegate.md" "team lead" "Delegate communicates with team lead"
assert_file_contains "$PROJECT_DIR/commands/delegate.md" "CAN write and edit code" "Write delegate has write permission"

scenario "Command has worktree isolation"

assert_file_contains "$PROJECT_DIR/commands/delegate.md" "worktree add" "Creates git worktree"
assert_file_contains "$PROJECT_DIR/commands/delegate.md" "delegate/" "Uses delegate/ branch prefix"
assert_file_contains "$PROJECT_DIR/commands/delegate.md" "never modify files in the main repo" "Enforces worktree isolation"
assert_file_contains "$PROJECT_DIR/commands/delegate.md" "\-B" "Uses -B flag for branch reset on rerun"
assert_file_contains "$PROJECT_DIR/commands/delegate.md" "worktree path already exists" "Handles stale worktree path"

scenario "Command supports concurrent delegates"

assert_file_contains "$PROJECT_DIR/commands/delegate.md" "delegate-\[short-task-slug\]" "Team name includes task slug"
assert_file_contains "$PROJECT_DIR/commands/delegate.md" "multiple delegates can run concurrently" "Documents concurrent support"

scenario "Command has cleanup instructions"

assert_file_contains "$PROJECT_DIR/commands/delegate.md" "shutdown_request" "Has shutdown mechanism"
assert_file_contains "$PROJECT_DIR/commands/delegate.md" "worktree remove" "Has worktree cleanup"
assert_file_contains "$PROJECT_DIR/commands/delegate.md" "TeamDelete" "Cleans up team"
assert_file_contains "$PROJECT_DIR/commands/delegate.md" "already exists" "Handles duplicate team"
assert_file_contains "$PROJECT_DIR/commands/delegate.md" "\-D instead of \-d" "Documents force delete for unmerged branches"

scenario "Command has error handling"

assert_file_contains "$PROJECT_DIR/commands/delegate.md" "spawning fails" "Has spawn failure handling"
assert_file_contains "$PROJECT_DIR/commands/delegate.md" "retry" "Mentions retry option"

scenario "Command is installed during fresh install"

run_install_expect '
    deselect_all_mcp
    deselect_all_skills
    decline_statusline
    decline_agent_teams
' > /dev/null

assert_file_exists "$CLAUDE_DIR/commands/delegate.md" "delegate.md installed"

# Verify installed file matches source
expected=$(sha256_file "$PROJECT_DIR/commands/delegate.md")
actual=$(sha256_file "$CLAUDE_DIR/commands/delegate.md")
if [[ "$expected" = "$actual" ]]; then
    pass "Installed delegate.md matches source"
else
    fail "Installed delegate.md does not match source"
fi

# Print summary
print_summary

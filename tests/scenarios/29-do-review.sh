#!/bin/bash

# Scenario: /do-review command structure
# Note: This tests the command file structure. Full E2E test would require
# Claude to execute the command with comprehensive-review plugin, which is tested manually.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

scenario "do-review.md command exists"

assert_file_exists "$PROJECT_DIR/commands/do-review.md" "do-review.md exists"

scenario "Command has prerequisite check"

assert_file_contains "$PROJECT_DIR/commands/do-review.md" "comprehensive-review" "References comprehensive-review plugin"
assert_file_contains "$PROJECT_DIR/commands/do-review.md" "not installed" "Has plugin-not-installed handling"

scenario "Command has review scopes"

assert_file_contains "$PROJECT_DIR/commands/do-review.md" "git diff HEAD" "Default scope is uncommitted changes"
assert_file_contains "$PROJECT_DIR/commands/do-review.md" "main...HEAD" "Branch diff scope"
assert_file_contains "$PROJECT_DIR/commands/do-review.md" "commit range" "Commit range scope"

scenario "Command has coding standards integration"

assert_file_contains "$PROJECT_DIR/commands/do-review.md" "coding standards" "Loads coding standards"
assert_file_contains "$PROJECT_DIR/commands/do-review.md" "skills" "Uses skills for standards"

scenario "Command spawns review agents via Task tool"

assert_file_contains "$PROJECT_DIR/commands/do-review.md" "architect-review" "Uses architect-review agent"
assert_file_contains "$PROJECT_DIR/commands/do-review.md" "code-reviewer" "Uses code-reviewer agent"
assert_file_contains "$PROJECT_DIR/commands/do-review.md" "security-auditor" "Uses security-auditor agent"
assert_file_contains "$PROJECT_DIR/commands/do-review.md" "Task tool" "Spawns via Task tool"

scenario "Command has security and full flags"

assert_file_contains "$PROJECT_DIR/commands/do-review.md" "\-\-security" "Has --security flag"
assert_file_contains "$PROJECT_DIR/commands/do-review.md" "\-\-full" "Has --full flag"

scenario "Command has post-review flow"

assert_file_contains "$PROJECT_DIR/commands/do-review.md" "Incorporate feedback" "Has incorporate feedback option"
assert_file_contains "$PROJECT_DIR/commands/do-review.md" "Pick specific items" "Allows partial incorporation"

scenario "Command has large changeset handling"

assert_file_contains "$PROJECT_DIR/commands/do-review.md" "Large changeset" "Warns on large diffs"

scenario "Command is installed during fresh install"

run_install_expect '
    deselect_all_mcp
    deselect_all_skills
    decline_statusline
    decline_agent_teams
' > /dev/null

assert_file_exists "$CLAUDE_DIR/commands/do-review.md" "do-review.md installed"

# Verify installed file matches source
expected=$(sha256_file "$PROJECT_DIR/commands/do-review.md")
actual=$(sha256_file "$CLAUDE_DIR/commands/do-review.md")
if [[ "$expected" = "$actual" ]]; then
    pass "Installed do-review.md matches source"
else
    fail "Installed do-review.md does not match source"
fi

# Print summary
print_summary

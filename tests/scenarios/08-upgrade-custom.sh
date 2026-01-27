#!/bin/bash

# Scenario: /upgrade-custom command structure

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

scenario "upgrade-custom.md command exists"

assert_file_exists "$PROJECT_DIR/commands/upgrade-custom.md" "upgrade-custom.md exists"

scenario "Command has required sections"

# shellcheck disable=SC2088 # Tilde is literal string to search for, not a path
assert_file_contains "$PROJECT_DIR/commands/upgrade-custom.md" "~/.claude/custom" "References custom directory"
assert_file_contains "$PROJECT_DIR/commands/upgrade-custom.md" "git pull" "Has pull instruction"
assert_file_contains "$PROJECT_DIR/commands/upgrade-custom.md" ".git" "Checks for git repo"
assert_file_contains "$PROJECT_DIR/commands/upgrade-custom.md" "/catchup" "Has catchup hint"

scenario "Command has error handling"

assert_file_contains "$PROJECT_DIR/commands/upgrade-custom.md" "No custom repo found" "Has no-repo error"
assert_file_contains "$PROJECT_DIR/commands/upgrade-custom.md" "not a git repository" "Has not-a-repo error"
assert_file_contains "$PROJECT_DIR/commands/upgrade-custom.md" "/add-custom" "References add-custom command"

scenario "Command has VERSION support"

assert_file_contains "$PROJECT_DIR/commands/upgrade-custom.md" "VERSION" "Has VERSION handling"
assert_file_contains "$PROJECT_DIR/commands/upgrade-custom.md" "custom_version" "Updates custom_version in installed.json"

# Print summary
print_summary

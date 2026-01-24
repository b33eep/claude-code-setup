#!/bin/bash

# Scenario: /upgrade-claude-setup command structure

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

scenario "upgrade-claude-setup.md command exists"

assert_file_exists "$PROJECT_DIR/commands/upgrade-claude-setup.md" "upgrade-claude-setup.md exists"

scenario "Command has required sections"

assert_file_contains "$PROJECT_DIR/commands/upgrade-claude-setup.md" "installed.json" "References installed.json"
assert_file_contains "$PROJECT_DIR/commands/upgrade-claude-setup.md" "content_version" "Checks content_version"
assert_file_contains "$PROJECT_DIR/commands/upgrade-claude-setup.md" "templates/VERSION" "Fetches VERSION"
assert_file_contains "$PROJECT_DIR/commands/upgrade-claude-setup.md" "git clone" "Has clone instruction"
assert_file_contains "$PROJECT_DIR/commands/upgrade-claude-setup.md" "install.sh --update" "Runs install.sh --update"
assert_file_contains "$PROJECT_DIR/commands/upgrade-claude-setup.md" "CHANGELOG" "References CHANGELOG"

scenario "Command has correct URLs"

assert_file_contains "$PROJECT_DIR/commands/upgrade-claude-setup.md" "claude-code-setup" "Uses correct repo name"

scenario "Command has error handling"

assert_file_contains "$PROJECT_DIR/commands/upgrade-claude-setup.md" "up-to-date" "Has up-to-date message"
assert_file_contains "$PROJECT_DIR/commands/upgrade-claude-setup.md" "Manual upgrade" "Has manual fallback"

scenario "Command uses --yes for non-interactive mode"

# Use grep -F for fixed string match (avoids -- being interpreted as option)
if grep -qF -- "--update --yes" "$PROJECT_DIR/commands/upgrade-claude-setup.md"; then
    pass "Uses --yes flag for non-interactive update"
else
    fail "Should use --yes flag for non-interactive update"
fi

# Print summary
print_summary

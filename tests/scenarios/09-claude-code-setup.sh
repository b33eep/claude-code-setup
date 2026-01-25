#!/bin/bash

# Scenario: /claude-code-setup command structure

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

scenario "claude-code-setup.md command exists"

assert_file_exists "$PROJECT_DIR/commands/claude-code-setup.md" "claude-code-setup.md exists"

scenario "Command has required sections"

assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "installed.json" "References installed.json"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "content_version" "Checks content_version"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "templates/VERSION" "Fetches VERSION"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "git clone" "Has clone instruction"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "install.sh --update" "Runs install.sh --update"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "CHANGELOG" "References CHANGELOG"

scenario "Command has correct URLs"

assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "claude-code-setup" "Uses correct repo name"

scenario "Command has error handling"

assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "up-to-date" "Has up-to-date message"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "Manual upgrade" "Has manual fallback"

scenario "Command uses --yes for non-interactive mode"

# Use grep -F for fixed string match (avoids -- being interpreted as option)
if grep -qF -- "--update --yes" "$PROJECT_DIR/commands/claude-code-setup.md"; then
    pass "Uses --yes flag for non-interactive update"
else
    fail "Should use --yes flag for non-interactive update"
fi

scenario "Command checks for new modules"

assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "Check for new modules" "Has new modules check step"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "install.sh --add" "Can install new modules"
assert_file_contains "$PROJECT_DIR/commands/claude-code-setup.md" "Modules available to install" "Shows available modules output"

# Print summary
print_summary

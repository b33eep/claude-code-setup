#!/bin/bash

# Scenario: Quick install script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

scenario "quick-install.sh is executable"

if [ -x "$PROJECT_DIR/quick-install.sh" ]; then
    pass "quick-install.sh is executable"
else
    fail "quick-install.sh is not executable"
fi

scenario "Git dependency check works"

# Create a fake environment without git in PATH
fake_bin="$TEST_DIR/fake-bin"
mkdir -p "$fake_bin"

# Run quick-install.sh with PATH that excludes git
output=$(PATH="$fake_bin" "$PROJECT_DIR/quick-install.sh" 2>&1) && status=0 || status=$?

if [ "$status" -ne 0 ] && echo "$output" | grep -q "git is required"; then
    pass "Git check fails correctly when git is missing"
else
    fail "Git check should fail when git is missing (status: $status, output: $output)"
fi

scenario "Script structure is correct"

# Verify script has required elements
assert_file_contains "$PROJECT_DIR/quick-install.sh" "set -euo pipefail" "Has defensive header"
assert_file_contains "$PROJECT_DIR/quick-install.sh" "command -v git" "Has git check"
assert_file_contains "$PROJECT_DIR/quick-install.sh" "mktemp -d" "Uses temp directory"
assert_file_contains "$PROJECT_DIR/quick-install.sh" "trap.*EXIT" "Has cleanup trap"
assert_file_contains "$PROJECT_DIR/quick-install.sh" "git clone" "Clones repository"
assert_file_contains "$PROJECT_DIR/quick-install.sh" "./install.sh" "Runs install.sh"

# Note: Full E2E test (curl | bash) requires script to be on GitHub main branch
# This is tested manually after merge

# Print summary
print_summary

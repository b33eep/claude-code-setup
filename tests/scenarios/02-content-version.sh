#!/bin/bash

# Scenario: Content version tracking

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

scenario "Content version is tracked correctly"

# Fresh install
printf 'none\nnone\n' | "$PROJECT_DIR/install.sh" > /dev/null

# Verify initial content version
assert_json_eq "$INSTALLED_FILE" ".content_version" "1" "Initial content_version is 1"

scenario "Update when already up-to-date"

# Run update - should say "up to date"
output=$("$PROJECT_DIR/install.sh" --update 2>&1)
if echo "$output" | grep -q "up to date"; then
    pass "Update detects up-to-date state"
else
    fail "Update should detect up-to-date state"
fi

scenario "Update when version differs"

# Manually set lower version to simulate outdated install
jq '.content_version = 0' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp" && mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"

# Run update - should prompt
output=$(printf 'n\n' | "$PROJECT_DIR/install.sh" --update 2>&1)
if echo "$output" | grep -q "v0 → v1"; then
    pass "Update shows version diff"
else
    fail "Update should show version diff (got: $output)"
fi

scenario "Update applies new version"

# Accept update
printf 'y\n' | "$PROJECT_DIR/install.sh" --update > /dev/null

# Verify version updated
assert_json_eq "$INSTALLED_FILE" ".content_version" "1" "content_version updated to 1"

# Print summary
print_summary

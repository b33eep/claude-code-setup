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

# Fresh install (no MCP, no skills, decline status line for simpler test)
printf 'none\nnone\nn\n' | "$PROJECT_DIR/install.sh" > /dev/null

# Verify initial content version
assert_json_eq "$INSTALLED_FILE" ".content_version" "2" "Initial content_version is 2"

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
if echo "$output" | grep -q "v0 → v2"; then
    pass "Update shows version diff"
else
    fail "Update should show version diff (got: $output)"
fi

scenario "Update applies new version"

# Accept update (decline new modules prompt)
printf 'y\nn\n' | "$PROJECT_DIR/install.sh" --update > /dev/null

# Verify version updated
assert_json_eq "$INSTALLED_FILE" ".content_version" "2" "content_version updated to 2"

scenario "Update shows new modules available"

# Set lower version again
jq '.content_version = 0' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp" && mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"

# Run update and check for new modules prompt
output=$(printf 'y\nn\n' | "$PROJECT_DIR/install.sh" --update 2>&1)

if echo "$output" | grep -q "New Modules Available"; then
    pass "Update shows 'New Modules Available'"
else
    fail "Update should show 'New Modules Available' (got: $output)"
fi

# Should list the available skills
if echo "$output" | grep -q "Skills:"; then
    pass "Update lists available skills"
else
    fail "Update should list available skills"
fi

scenario "Update can install new modules"

# Set lower version again
jq '.content_version = 0' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp" && mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"

# Accept update and install standards-python (first non-installed skill)
# After fresh install: none installed, so 1=create-slidev, 2=standards-python...
printf 'y\ny\nnone\n2\n' | "$PROJECT_DIR/install.sh" --update > /dev/null

# Verify skill was installed
assert_dir_exists "$CLAUDE_DIR/skills/standards-python" "standards-python installed via update"
assert_json_exists "$INSTALLED_FILE" '.skills[] | select(. == "standards-python")' "standards-python tracked"

# Print summary
print_summary

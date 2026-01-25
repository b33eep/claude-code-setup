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

# Read expected version dynamically
EXPECTED_VERSION=$(cat "$PROJECT_DIR/templates/VERSION" | tr -d '[:space:]')

scenario "Content version is tracked correctly"

# Fresh install (no MCP, no skills, decline status line for simpler test)
printf 'none\nnone\nn\n' | "$PROJECT_DIR/install.sh" > /dev/null

# Verify content_version field exists (not the specific value - that changes with every release)
assert_json_exists "$INSTALLED_FILE" ".content_version" "content_version field exists"

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

# Run update - should prompt with version diff
output=$(printf 'n\n' | "$PROJECT_DIR/install.sh" --update 2>&1)
if echo "$output" | grep -q "v0 → v${EXPECTED_VERSION}"; then
    pass "Update shows version diff (v0 → v${EXPECTED_VERSION})"
else
    fail "Update should show version diff v0 → v${EXPECTED_VERSION} (got: $output)"
fi

scenario "Update applies new version"

# Accept update (decline new modules prompt)
printf 'y\nn\n' | "$PROJECT_DIR/install.sh" --update > /dev/null

# Verify version updated to current
assert_json_eq "$INSTALLED_FILE" ".content_version" "$EXPECTED_VERSION" "content_version updated to v${EXPECTED_VERSION}"

# Verify project template was updated
assert_file_exists "$CLAUDE_DIR/templates/CLAUDE.template.md" "Project template updated"

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

# Accept update and install standards-python
# After fresh install: none installed, so 1=create-slidev, 2=skill-creator, 3=standards-javascript, 4=standards-python...
printf 'y\ny\nnone\n4\n' | "$PROJECT_DIR/install.sh" --update > /dev/null

# Verify skill was installed
assert_dir_exists "$CLAUDE_DIR/skills/standards-python" "standards-python installed via update"
assert_json_exists "$INSTALLED_FILE" '.skills[] | select(. == "standards-python")' "standards-python tracked"

scenario "Update with --yes flag (non-interactive)"

# Set lower version
jq '.content_version = 0' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp" && mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"

# Run update with --yes - should not require any input
output=$("$PROJECT_DIR/install.sh" --update --yes 2>&1)

# Should complete without prompting
if echo "$output" | grep -q "Update complete"; then
    pass "--yes completes update without prompting"
else
    fail "--yes should complete update (got: $output)"
fi

# Version should be updated
assert_json_eq "$INSTALLED_FILE" ".content_version" "$EXPECTED_VERSION" "--yes updates content_version"

scenario "Update with --yes skips new modules prompt"

# Set lower version
jq '.content_version = 0' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp" && mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"

# Run update with --yes
output=$("$PROJECT_DIR/install.sh" --update --yes 2>&1)

# Should NOT show "New Modules Available" (skipped in non-interactive mode)
if echo "$output" | grep -q "New Modules Available"; then
    fail "--yes should skip 'New Modules Available' prompt"
else
    pass "--yes skips new modules prompt"
fi

scenario "Update with -y short flag"

# Set lower version
jq '.content_version = 0' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp" && mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"

# Run update with -y (short form)
output=$("$PROJECT_DIR/install.sh" --update -y 2>&1)

if echo "$output" | grep -q "Update complete"; then
    pass "-y short flag works"
else
    fail "-y short flag should work (got: $output)"
fi

# Print summary
print_summary

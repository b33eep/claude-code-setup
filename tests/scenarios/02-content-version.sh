#!/bin/bash

# Scenario: Content version tracking

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

# Read expected version dynamically
EXPECTED_VERSION=$(cat "$PROJECT_DIR/templates/VERSION" | tr -d '[:space:]')

scenario "Content version is tracked correctly"

# Fresh install: deselect all MCP and all skills, decline status line
# Uses dynamic helpers that determine count from prompt
run_install_expect '
    # Deselect all MCP (pdf-reader is pre-selected)
    deselect_all_mcp

    # Deselect all skills (all pre-selected)
    deselect_all_skills

    # Decline status line
    decline_statusline
' > /dev/null

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

# Run update - should prompt with version diff, decline
run_update_expect '
    expect {
        -re {v0 → v[0-9]+} { send "n\r" }
        timeout { puts "TIMEOUT at version diff"; exit 1 }
    }
' > /tmp/update-output.txt 2>&1

if grep -q "v0 → v${EXPECTED_VERSION}" /tmp/update-output.txt; then
    pass "Update shows version diff (v0 → v${EXPECTED_VERSION})"
else
    fail "Update should show version diff v0 → v${EXPECTED_VERSION}"
fi

scenario "Update applies new version"

# Accept update (decline new modules prompt)
# Note: "Update complete" appears BEFORE "Install new modules?" prompt
run_update_expect '
    expect {
        {Proceed?} { send "y\r" }
        timeout { puts "TIMEOUT at continue"; exit 1 }
    }
    expect {
        {Install new modules?} { send "n\r" }
        timeout { puts "TIMEOUT at new modules"; exit 1 }
    }
' > /dev/null

# Verify version updated to current
assert_json_eq "$INSTALLED_FILE" ".content_version" "$EXPECTED_VERSION" "content_version updated to v${EXPECTED_VERSION}"

# Verify project template was updated
assert_file_exists "$CLAUDE_DIR/templates/CLAUDE.template.md" "Project template updated"

scenario "Update shows new modules available"

# Set lower version again
jq '.content_version = 0' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp" && mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"

# Run update and check for new modules prompt
run_update_expect '
    expect {
        {Proceed?} { send "y\r" }
        timeout { puts "TIMEOUT at continue"; exit 1 }
    }
    expect {
        {Install new modules?} { send "n\r" }
        timeout { puts "TIMEOUT at new modules"; exit 1 }
    }
' > /tmp/update-output.txt 2>&1

if grep -q "New Modules Available" /tmp/update-output.txt; then
    pass "Update shows 'New Modules Available'"
else
    fail "Update should show 'New Modules Available'"
fi

# Should list the available skills
if grep -q "Skills:" /tmp/update-output.txt; then
    pass "Update lists available skills"
else
    fail "Update should list available skills"
fi

scenario "Update can install new modules"

# Set lower version again
jq '.content_version = 0' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp" && mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"

# Accept update and install only standards-python
# Skill order (alphabetical): 1=create-slidev, 2=skill-creator, 3=standards-gradle,
#   4=standards-java, 5=standards-javascript, 6=standards-kotlin, 7=standards-python, 8=standards-shell, 9=standards-typescript, 10=youtube-transcript
run_update_expect '
    expect {
        {Proceed?} { send "y\r" }
        timeout { puts "TIMEOUT at continue"; exit 1 }
    }
    expect {
        {Install new modules?} { send "y\r" }
        timeout { puts "TIMEOUT at new modules"; exit 1 }
    }
    # MCP selection - deselect all
    deselect_all_mcp
    # Skills selection - keep only standards-python (#7)
    select_only_skill 7
' > /dev/null

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

scenario "Migration removes obsolete clear-session.md"

# Set lower version (pre-v16)
jq '.content_version = 15' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp" && mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"

# Create the obsolete file (simulates old install)
touch "$CLAUDE_DIR/commands/clear-session.md"

# Verify it exists before update
if [[ -f "$CLAUDE_DIR/commands/clear-session.md" ]]; then
    pass "clear-session.md exists before update"
else
    fail "clear-session.md should exist before update"
fi

# Run update
"$PROJECT_DIR/install.sh" --update -y > /dev/null 2>&1

# Verify it's gone after update
if [[ ! -f "$CLAUDE_DIR/commands/clear-session.md" ]]; then
    pass "clear-session.md removed by migration"
else
    fail "clear-session.md should be removed by v16 migration"
fi

# Verify wrapup.md exists
if [[ -f "$CLAUDE_DIR/commands/wrapup.md" ]]; then
    pass "wrapup.md exists after update"
else
    fail "wrapup.md should exist after update"
fi

# Print summary
print_summary

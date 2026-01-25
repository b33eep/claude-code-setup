#!/bin/bash

# Scenario: Fresh installation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

scenario "Fresh install with pdf-reader and standards-python"

# Run install: select pdf-reader (3), standards-python (4), enable status line (Y)
# MCP: 1=brave-search, 2=google-search, 3=pdf-reader
# Skills: 1=create-slidev, 2=skill-creator, 3=standards-javascript, 4=standards-python, 5=standards-shell, 6=standards-typescript
printf '3\n4\nY\n' | "$PROJECT_DIR/install.sh" > /dev/null

# Verify core files
assert_file_exists "$CLAUDE_DIR/CLAUDE.md" "CLAUDE.md created"
assert_file_exists "$INSTALLED_FILE" "installed.json created"
assert_dir_exists "$CLAUDE_DIR/commands" "commands directory created"

# Verify CLAUDE.md content matches template exactly
expected_hash=$(sha256_file "$PROJECT_DIR/templates/base/global-CLAUDE.md")
actual_hash=$(sha256_file "$CLAUDE_DIR/CLAUDE.md")
if [ "$expected_hash" = "$actual_hash" ]; then
    pass "CLAUDE.md matches template (hash: ${expected_hash:0:12}...)"
else
    fail "CLAUDE.md differs from template (expected: ${expected_hash:0:12}..., got: ${actual_hash:0:12}...)"
fi

# Verify installed.json
assert_json_exists "$INSTALLED_FILE" ".content_version" "content_version field exists"

# Verify MCP config
assert_file_exists "$MCP_CONFIG_FILE" ".claude.json created"
assert_json_exists "$MCP_CONFIG_FILE" '.mcpServers["pdf-reader"]' "pdf-reader configured"

# Verify skills match source
assert_dir_exists "$CLAUDE_DIR/skills/standards-python" "standards-python skill installed"
expected=$(sha256_file "$PROJECT_DIR/skills/standards-python/SKILL.md")
actual=$(sha256_file "$CLAUDE_DIR/skills/standards-python/SKILL.md")
if [ "$expected" = "$actual" ]; then
    pass "standards-python/SKILL.md matches source"
else
    fail "standards-python/SKILL.md differs from source"
fi

# Verify commands match source
for cmd in catchup.md clear-session.md init-project.md; do
    expected=$(sha256_file "$PROJECT_DIR/commands/$cmd")
    actual=$(sha256_file "$CLAUDE_DIR/commands/$cmd")
    if [ "$expected" = "$actual" ]; then
        pass "$cmd matches source"
    else
        fail "$cmd differs from source"
    fi
done

# Verify project template installed
assert_file_exists "$CLAUDE_DIR/templates/CLAUDE.template.md" "Project template installed"
expected=$(sha256_file "$PROJECT_DIR/templates/project-CLAUDE.md")
actual=$(sha256_file "$CLAUDE_DIR/templates/CLAUDE.template.md")
if [ "$expected" = "$actual" ]; then
    pass "CLAUDE.template.md matches source"
else
    fail "CLAUDE.template.md differs from source"
fi

# Verify init-project.md references the template path
assert_file_contains "$CLAUDE_DIR/commands/init-project.md" "CLAUDE.template.md" "init-project references template"

# Print summary
print_summary

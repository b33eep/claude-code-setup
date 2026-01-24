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

# Run install: select pdf-reader (3), standards-python (2), enable status line (Y)
# MCP: 1=brave-search, 2=google-search, 3=pdf-reader
# Skills: 1=create-slidev-presentation, 2=standards-python, 3=standards-shell, 4=standards-typescript
printf '3\n2\nY\n' | "$PROJECT_DIR/install.sh" > /dev/null

# Verify core files
assert_file_exists "$CLAUDE_DIR/CLAUDE.md" "CLAUDE.md created"
assert_file_exists "$INSTALLED_FILE" "installed.json created"
assert_dir_exists "$CLAUDE_DIR/commands" "commands directory created"

# Verify CLAUDE.md content matches template exactly
expected_hash=$(shasum -a 256 "$PROJECT_DIR/templates/base/global-CLAUDE.md" | cut -d' ' -f1)
actual_hash=$(shasum -a 256 "$CLAUDE_DIR/CLAUDE.md" | cut -d' ' -f1)
if [ "$expected_hash" = "$actual_hash" ]; then
    pass "CLAUDE.md matches template (hash: ${expected_hash:0:12}...)"
else
    fail "CLAUDE.md differs from template (expected: ${expected_hash:0:12}..., got: ${actual_hash:0:12}...)"
fi

# Verify installed.json
assert_json_exists "$INSTALLED_FILE" ".content_version" "content_version field exists"
assert_json_eq "$INSTALLED_FILE" ".content_version" "4" "content_version is 4"

# Verify MCP config
assert_file_exists "$MCP_CONFIG_FILE" ".claude.json created"
assert_json_exists "$MCP_CONFIG_FILE" '.mcpServers["pdf-reader"]' "pdf-reader configured"

# Verify skills match source
assert_dir_exists "$CLAUDE_DIR/skills/standards-python" "standards-python skill installed"
expected=$(shasum -a 256 "$PROJECT_DIR/skills/standards-python/SKILL.md" | cut -d' ' -f1)
actual=$(shasum -a 256 "$CLAUDE_DIR/skills/standards-python/SKILL.md" | cut -d' ' -f1)
if [ "$expected" = "$actual" ]; then
    pass "standards-python/SKILL.md matches source"
else
    fail "standards-python/SKILL.md differs from source"
fi

# Verify commands match source
for cmd in catchup.md clear-session.md init-project.md; do
    expected=$(shasum -a 256 "$PROJECT_DIR/commands/$cmd" | cut -d' ' -f1)
    actual=$(shasum -a 256 "$CLAUDE_DIR/commands/$cmd" | cut -d' ' -f1)
    if [ "$expected" = "$actual" ]; then
        pass "$cmd matches source"
    else
        fail "$cmd differs from source"
    fi
done

# Print summary
print_summary

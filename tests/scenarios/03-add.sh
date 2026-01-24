#!/bin/bash

# Scenario: Adding modules with --add

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

scenario "Initial install with minimal modules"

# Install with no MCP, no skills, decline status line
printf 'none\nnone\nn\n' | "$PROJECT_DIR/install.sh" > /dev/null

assert_file_exists "$INSTALLED_FILE" "installed.json exists"

scenario "Add skill via --add"

# Add standards-typescript
# After fresh install, all skills show with numbers (none installed yet):
# 1=create-slidev, 2=standards-python, 3=standards-shell, 4=standards-typescript
# Status line prompt: decline again
printf 'none\n4\nn\n' | "$PROJECT_DIR/install.sh" --add > /dev/null

assert_dir_exists "$CLAUDE_DIR/skills/standards-typescript" "standards-typescript installed"
assert_json_exists "$INSTALLED_FILE" '.skills[] | select(. == "standards-typescript")' "skill tracked in installed.json"

scenario "Add standards-shell skill"

# Add standards-shell
# Now standards-typescript shows as [installed] without number:
# 1=create-slidev, 2=standards-python, 3=standards-shell
# standards-typescript [installed]
# Status line prompt: decline again
printf 'none\n3\nn\n' | "$PROJECT_DIR/install.sh" --add > /dev/null

assert_dir_exists "$CLAUDE_DIR/skills/standards-shell" "standards-shell installed"
assert_json_exists "$INSTALLED_FILE" '.skills[] | select(. == "standards-shell")' "standards-shell tracked in installed.json"

# Verify content matches source
expected=$(shasum -a 256 "$PROJECT_DIR/skills/standards-shell/SKILL.md" | cut -d' ' -f1)
actual=$(shasum -a 256 "$CLAUDE_DIR/skills/standards-shell/SKILL.md" | cut -d' ' -f1)
if [ "$expected" = "$actual" ]; then
    pass "standards-shell/SKILL.md matches source"
else
    fail "standards-shell/SKILL.md differs from source"
fi

scenario "Add MCP via --add"

# Add pdf-reader (doesn't require API key)
# Available MCP: 1=brave-search, 2=google-search, 3=pdf-reader
# Status line prompt: decline again
printf '3\nnone\nn\n' | "$PROJECT_DIR/install.sh" --add > /dev/null

assert_json_exists "$MCP_CONFIG_FILE" '.mcpServers["pdf-reader"]' "pdf-reader configured"
assert_json_exists "$INSTALLED_FILE" '.mcp[] | select(. == "pdf-reader")' "mcp tracked in installed.json"

scenario "Add MCP with API key"

# Add brave-search with dummy API key
# Order: MCP selection, Skills selection, API key prompt (during MCP install), Status line prompt
printf '1\nnone\ntest-api-key-12345\nn\n' | "$PROJECT_DIR/install.sh" --add > /dev/null

assert_json_exists "$MCP_CONFIG_FILE" '.mcpServers["brave-search"]' "brave-search configured"
assert_json_eq "$MCP_CONFIG_FILE" '.mcpServers["brave-search"].env.BRAVE_API_KEY' "test-api-key-12345" "API key stored correctly"

scenario "--add shows installed modules with [installed] marker"

# Run --add and capture output (decline status line)
output=$(printf 'none\nnone\nn\n' | "$PROJECT_DIR/install.sh" --add 2>&1)

# Check that installed modules show [installed]
if echo "$output" | grep -q "standards-typescript \[installed\]"; then
    pass "standards-typescript shows [installed] marker"
else
    fail "standards-typescript should show [installed] marker"
fi

if echo "$output" | grep -q "standards-shell \[installed\]"; then
    pass "standards-shell shows [installed] marker"
else
    fail "standards-shell should show [installed] marker"
fi

# Check that non-installed modules show with number
if echo "$output" | grep -q "1) create-slidev"; then
    pass "create-slidev shows with selection number"
else
    fail "create-slidev should show with selection number"
fi

# Print summary
print_summary

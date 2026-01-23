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

# Install with no MCP, no skills
printf 'none\nnone\n' | "$PROJECT_DIR/install.sh" > /dev/null

assert_file_exists "$INSTALLED_FILE" "installed.json exists"

scenario "Add skill via --add"

# Add standards-typescript
# Available skills after fresh install: 1=create-slidev, 2=standards-python, 3=standards-typescript
printf 'none\n3\n' | "$PROJECT_DIR/install.sh" --add > /dev/null

assert_dir_exists "$CLAUDE_DIR/skills/standards-typescript" "standards-typescript installed"
assert_json_exists "$INSTALLED_FILE" '.skills[] | select(. == "standards-typescript")' "skill tracked in installed.json"

scenario "Add MCP via --add"

# Add pdf-reader (doesn't require API key)
# Available MCP: 1=brave-search, 2=google-search, 3=pdf-reader
printf '3\nnone\n' | "$PROJECT_DIR/install.sh" --add > /dev/null

assert_json_exists "$MCP_CONFIG_FILE" '.mcpServers["pdf-reader"]' "pdf-reader configured"
assert_json_exists "$INSTALLED_FILE" '.mcp[] | select(. == "pdf-reader")' "mcp tracked in installed.json"

scenario "Add MCP with API key"

# Add brave-search with dummy API key
# Order: MCP selection, Skills selection, then API key prompt
printf '1\nnone\ntest-api-key-12345\n' | "$PROJECT_DIR/install.sh" --add > /dev/null

assert_json_exists "$MCP_CONFIG_FILE" '.mcpServers["brave-search"]' "brave-search configured"
assert_json_eq "$MCP_CONFIG_FILE" '.mcpServers["brave-search"].env.BRAVE_API_KEY' "test-api-key-12345" "API key stored correctly"

# Print summary
print_summary

#!/bin/bash

# Scenario: /add-custom command structure
# Note: This tests the command file structure. Full E2E test would require
# Claude to execute the command, which is tested manually.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

scenario "add-custom.md command exists"

assert_file_exists "$PROJECT_DIR/commands/add-custom.md" "add-custom.md exists"

scenario "Command has required sections"

assert_file_contains "$PROJECT_DIR/commands/add-custom.md" "Validate URL format" "Has URL validation step"
assert_file_contains "$PROJECT_DIR/commands/add-custom.md" "git clone" "Has clone instruction"
assert_file_contains "$PROJECT_DIR/commands/add-custom.md" "remote get-url" "Has remote check"
assert_file_contains "$PROJECT_DIR/commands/add-custom.md" "/claude-code-setup" "Has next step hint"

scenario "Command has VERSION support"

assert_file_contains "$PROJECT_DIR/commands/add-custom.md" "VERSION" "Has VERSION handling"
assert_file_contains "$PROJECT_DIR/commands/add-custom.md" "custom_version" "Updates custom_version in installed.json"
assert_file_contains "$PROJECT_DIR/commands/add-custom.md" "custom_url" "Updates custom_url in installed.json"

scenario "Command has error handling"

assert_file_contains "$PROJECT_DIR/commands/add-custom.md" "Permission denied" "Has auth error message"
assert_file_contains "$PROJECT_DIR/commands/add-custom.md" "Insecure URL rejected" "Has http:// rejection error"
assert_file_contains "$PROJECT_DIR/commands/add-custom.md" "Invalid Git URL" "Has invalid URL error"
assert_file_contains "$PROJECT_DIR/commands/add-custom.md" "not a git repository" "Has not-a-repo error"

scenario "install.sh supports custom modules"

# Verify install.sh has CUSTOM_DIR variable
assert_file_contains "$PROJECT_DIR/install.sh" 'CUSTOM_DIR=' "install.sh has CUSTOM_DIR"
assert_file_contains "$PROJECT_DIR/install.sh" 'CUSTOM_DIR/mcp' "install.sh checks custom MCP"
assert_file_contains "$PROJECT_DIR/install.sh" 'CUSTOM_DIR/skills' "install.sh checks custom skills"

# Print summary
print_summary

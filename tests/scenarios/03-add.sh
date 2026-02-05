#!/bin/bash

# Scenario: Adding modules with --add

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

scenario "Initial install with minimal modules"

# Install with no MCP, no skills, decline status line
# Uses dynamic helpers that determine count from prompt
run_install_expect '
    # Deselect all MCP (pdf-reader is pre-selected)
    deselect_all_mcp

    # Deselect all skills (all pre-selected)
    deselect_all_skills

    # Decline status line
    decline_statusline
' > /dev/null

assert_file_exists "$INSTALLED_FILE" "installed.json exists"

scenario "Add skill via --add"

# Add standards-typescript only
# Skill order (alphabetical, 6 available): 1=create-slidev, 2=skill-creator,
#   3=standards-javascript, 4=standards-python, 5=standards-shell, 6=standards-typescript
run_add_expect '
    # No MCP - deselect all
    deselect_all_mcp

    # Select only standards-typescript (#6)
    select_only_skill 7

    # Decline status line (not configured in initial install)
    decline_statusline
' > /dev/null

assert_dir_exists "$CLAUDE_DIR/skills/standards-typescript" "standards-typescript installed"
assert_json_exists "$INSTALLED_FILE" '.skills[] | select(. == "standards-typescript")' "skill tracked in installed.json"

scenario "Add standards-shell skill"

# Add standards-shell only
# After previous install, standards-typescript is installed, so 5 skills remain:
# 1=create-slidev, 2=skill-creator, 3=standards-javascript, 4=standards-python, 5=standards-shell
run_add_expect '
    # No MCP - deselect all
    deselect_all_mcp

    # Select only standards-shell (#5 of remaining 5)
    select_only_skill 6

    # Decline status line
    decline_statusline
' > /dev/null

assert_dir_exists "$CLAUDE_DIR/skills/standards-shell" "standards-shell installed"
assert_json_exists "$INSTALLED_FILE" '.skills[] | select(. == "standards-shell")' "standards-shell tracked in installed.json"

# Verify content matches source
expected=$(sha256_file "$PROJECT_DIR/skills/standards-shell/SKILL.md")
actual=$(sha256_file "$CLAUDE_DIR/skills/standards-shell/SKILL.md")
if [ "$expected" = "$actual" ]; then
    pass "standards-shell/SKILL.md matches source"
else
    fail "standards-shell/SKILL.md differs from source"
fi

scenario "Add MCP via --add"

# Add pdf-reader (doesn't require API key)
# MCP: pdf-reader is pre-selected by default, so just confirm
run_add_expect '
    # pdf-reader is pre-selected, just confirm
    confirm_mcp

    # No skills - deselect all (4 remaining after previous installs)
    deselect_all_skills

    # Decline status line
    decline_statusline
' > /dev/null

assert_json_exists "$MCP_CONFIG_FILE" '.mcpServers["pdf-reader"]' "pdf-reader configured"
assert_json_exists "$INSTALLED_FILE" '.mcp[] | select(. == "pdf-reader")' "mcp tracked in installed.json"

scenario "Add MCP with API key"

# Add brave-search with dummy API key
# MCP: 1=brave-search, 2=google-search (pdf-reader is already installed)
# Note: brave-search is NOT pre-selected (requires API key), so we toggle it ON
run_add_expect '
    # Toggle brave-search ON (#1 of 2 remaining MCP)
    toggle_mcp 1
    confirm_mcp

    # No skills - deselect all (4 remaining)
    deselect_all_skills

    # Enter API key for brave-search
    enter_api_key "test-api-key-12345"

    # Decline status line
    decline_statusline
' > /dev/null

assert_json_exists "$MCP_CONFIG_FILE" '.mcpServers["brave-search"]' "brave-search configured"
assert_json_eq "$MCP_CONFIG_FILE" '.mcpServers["brave-search"].env.BRAVE_API_KEY' "test-api-key-12345" "API key stored correctly"

scenario "--add shows installed modules with [installed] marker"

# Run --add and capture output
# Use deselect_all_skills to avoid installing youtube-transcript
# (its deps yt-dlp/ffmpeg take too long on macOS, causing timeout)
output=$(run_add_expect '
    # Just confirm defaults and capture output
    confirm_mcp
    deselect_all_skills

    # Decline status line
    decline_statusline
' 2>&1)

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

# Check that non-installed modules show in the toggle list with [x] or [ ]
if echo "$output" | grep -q "create-slidev"; then
    pass "create-slidev shows in selection list"
else
    fail "create-slidev should show in selection list"
fi

# Print summary
print_summary

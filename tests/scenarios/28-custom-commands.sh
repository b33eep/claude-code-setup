#!/bin/bash

# Scenario: Custom commands override, extend, scripts, edge cases, update cleanup

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

setup_test_env
trap cleanup_test_env EXIT

# ============================================
# Setup custom files BEFORE install
# ============================================

mkdir -p "$CUSTOM_DIR/commands"
mkdir -p "$CUSTOM_DIR/scripts"

# Override command (no marker)
cat > "$CUSTOM_DIR/commands/wrapup.md" << 'CUSTOM_EOF'
# Custom Wrapup Override
This completely replaces the base wrapup command.
CUSTOM_EOF

# Extend command (with marker)
cat > "$CUSTOM_DIR/commands/catchup.md" << 'CUSTOM_EOF'
# Custom Catchup Preamble
Do custom stuff first.

---

{{base:catchup}}
CUSTOM_EOF

# Path traversal attempt
cat > "$CUSTOM_DIR/commands/test-traversal.md" << 'CUSTOM_EOF'
# Test Traversal
{{base:../../etc/passwd}}
CUSTOM_EOF

# Missing base reference
cat > "$CUSTOM_DIR/commands/test-missing.md" << 'CUSTOM_EOF'
# Test Missing
{{base:nonexistent}}
CUSTOM_EOF

# Empty base name
cat > "$CUSTOM_DIR/commands/test-empty.md" << 'CUSTOM_EOF'
# Test Empty
{{base:}}
CUSTOM_EOF

# Multiple markers in one file
cat > "$CUSTOM_DIR/commands/test-multi.md" << 'CUSTOM_EOF'
# Multi Marker Test
First base:
{{base:init-project}}
---
Second base:
{{base:catchup}}
CUSTOM_EOF

# Custom script
cat > "$CUSTOM_DIR/scripts/helper.sh" << 'CUSTOM_EOF'
#!/bin/bash
echo "Helper script"
CUSTOM_EOF

# ============================================
# Fresh install
# ============================================

scenario "Fresh install with custom commands, scripts, and edge cases"

run_install_expect '
    confirm_mcp
    confirm_skills
    decline_statusline
    decline_agent_teams
' > /dev/null

assert_file_exists "$CLAUDE_DIR/commands/wrapup.md" "wrapup.md installed"
assert_file_exists "$CLAUDE_DIR/commands/catchup.md" "catchup.md installed"
assert_file_exists "$CLAUDE_DIR/scripts/helper.sh" "helper.sh installed"

# ============================================
# Override mode
# ============================================

scenario "Custom command override (no marker replaces base)"

assert_file_contains "$CLAUDE_DIR/commands/wrapup.md" "Custom Wrapup Override" "Contains custom content"
if grep -q "Wrapup: Document and Restart" "$CLAUDE_DIR/commands/wrapup.md" 2>/dev/null; then
    fail "Override should not contain base content"
else
    pass "Override does not contain base content"
fi

# ============================================
# Extend mode
# ============================================

scenario "Custom command extend (marker replaced with base)"

assert_file_contains "$CLAUDE_DIR/commands/catchup.md" "Custom Catchup Preamble" "Contains custom preamble"
# Verify base content was merged (merged file should be much larger than custom-only)
custom_words=$(wc -w < "$CUSTOM_DIR/commands/catchup.md")
merged_words=$(wc -w < "$CLAUDE_DIR/commands/catchup.md")
if (( merged_words > custom_words + 50 )); then
    pass "Base content merged (${custom_words} → ${merged_words} words)"
else
    fail "Base content not merged (${custom_words} → ${merged_words} words)"
fi
if grep -q '{{base:' "$CLAUDE_DIR/commands/catchup.md" 2>/dev/null; then
    fail "Raw marker should not remain"
else
    pass "No raw marker in output"
fi

# ============================================
# Custom scripts
# ============================================

scenario "Custom scripts installed with executable permission"

assert_cmd "Script is executable" test -x "$CLAUDE_DIR/scripts/helper.sh"
assert_file_contains "$CLAUDE_DIR/scripts/helper.sh" "Helper script" "Script content correct"

# ============================================
# Path traversal blocked
# ============================================

scenario "Path traversal attempt blocked"

assert_file_exists "$CLAUDE_DIR/commands/test-traversal.md" "test-traversal.md installed"
assert_file_contains "$CLAUDE_DIR/commands/test-traversal.md" "WARNING" "Has warning comment"
if grep -q "root:" "$CLAUDE_DIR/commands/test-traversal.md" 2>/dev/null; then
    fail "Path traversal was NOT blocked"
else
    pass "No /etc/passwd content in file"
fi

# ============================================
# Missing base command
# ============================================

scenario "Missing base command gets warning comment"

assert_file_contains "$CLAUDE_DIR/commands/test-missing.md" "WARNING" "Has warning comment"
assert_file_contains "$CLAUDE_DIR/commands/test-missing.md" "nonexistent" "Warning mentions command name"
if grep -q '{{base:' "$CLAUDE_DIR/commands/test-missing.md" 2>/dev/null; then
    fail "Raw marker should not remain"
else
    pass "No raw marker in output"
fi

# ============================================
# Empty base name
# ============================================

scenario "Empty base name rejected with warning"

assert_file_contains "$CLAUDE_DIR/commands/test-empty.md" "WARNING" "Has warning comment"
if grep -q '{{base:}}' "$CLAUDE_DIR/commands/test-empty.md" 2>/dev/null; then
    fail "Raw empty marker should not remain"
else
    pass "Empty marker resolved to warning"
fi

# ============================================
# Tracking in installed.json
# ============================================

scenario "Custom commands and scripts tracked in installed.json"

assert_json_exists "$INSTALLED_FILE" '.command_overrides' "command_overrides array exists"
assert_json_exists "$INSTALLED_FILE" '.scripts' "scripts array exists"

if jq -e '.command_overrides | index("wrapup.md")' "$INSTALLED_FILE" > /dev/null 2>&1; then
    pass "wrapup.md tracked as override"
else
    fail "wrapup.md not tracked"
fi
if jq -e '.command_overrides | index("catchup.md")' "$INSTALLED_FILE" > /dev/null 2>&1; then
    pass "catchup.md tracked as override"
else
    fail "catchup.md not tracked"
fi
if jq -e '.scripts | index("helper.sh")' "$INSTALLED_FILE" > /dev/null 2>&1; then
    pass "helper.sh tracked in scripts"
else
    fail "helper.sh not tracked"
fi

# ============================================
# --list shows custom commands and scripts
# ============================================

scenario "--list output includes custom commands and scripts"

list_output=$(HOME="$TEST_DIR" CLAUDE_DIR="$CLAUDE_DIR" MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
    "$PROJECT_DIR/install.sh" --list 2>&1)

if echo "$list_output" | grep -q "Custom Commands:"; then
    pass "--list has Custom Commands section"
else
    fail "--list missing Custom Commands section"
fi
if echo "$list_output" | grep -q "wrapup.md.*(override)"; then
    pass "wrapup.md labeled as (override)"
else
    fail "wrapup.md not labeled as (override)"
fi
if echo "$list_output" | grep -q "catchup.md.*(extend)"; then
    pass "catchup.md labeled as (extend)"
else
    fail "catchup.md not labeled as (extend)"
fi
if echo "$list_output" | grep -q "Custom Scripts:"; then
    pass "--list has Custom Scripts section"
else
    fail "--list missing Custom Scripts section"
fi
if echo "$list_output" | grep -q "helper.sh"; then
    pass "--list shows helper.sh"
else
    fail "--list missing helper.sh"
fi

# ============================================
# Update re-applies custom commands
# ============================================

scenario "Update re-applies custom overrides and extends"

# Lower version to trigger update
jq '.content_version = 0' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp" && mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"

HOME="$TEST_DIR" CLAUDE_DIR="$CLAUDE_DIR" MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
    SKIP_SKILL_DEPS=1 SKIP_EXTERNAL_PLUGINS=1 \
    "$PROJECT_DIR/install.sh" --update --yes > /dev/null 2>&1

assert_file_contains "$CLAUDE_DIR/commands/wrapup.md" "Custom Wrapup Override" "Override survives update"
assert_file_contains "$CLAUDE_DIR/commands/catchup.md" "Custom Catchup Preamble" "Extend preamble survives update"
merged_words=$(wc -w < "$CLAUDE_DIR/commands/catchup.md")
if (( merged_words > 50 )); then
    pass "Extend base content re-merged ($merged_words words)"
else
    fail "Extend base content not re-merged ($merged_words words)"
fi

# ============================================
# Cleanup: custom command removed restores base
# ============================================

scenario "Cleanup restores base when custom command removed"

# Remove custom override from source
rm "$CUSTOM_DIR/commands/wrapup.md"

# Lower version to trigger update
jq '.content_version = 0' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp" && mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"

HOME="$TEST_DIR" CLAUDE_DIR="$CLAUDE_DIR" MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
    SKIP_SKILL_DEPS=1 SKIP_EXTERNAL_PLUGINS=1 \
    "$PROJECT_DIR/install.sh" --update --yes > /dev/null 2>&1

# Base wrapup should be restored
expected=$(sha256_file "$PROJECT_DIR/commands/wrapup.md")
actual=$(sha256_file "$CLAUDE_DIR/commands/wrapup.md")
if [ "$expected" = "$actual" ]; then
    pass "wrapup.md restored to base version"
else
    fail "wrapup.md not restored to base (hash mismatch)"
fi

# wrapup.md should be removed from tracking
if jq -e '.command_overrides | index("wrapup.md")' "$INSTALLED_FILE" > /dev/null 2>&1; then
    fail "wrapup.md still tracked after removal"
else
    pass "wrapup.md removed from tracking"
fi

# catchup.md (extend) should still be custom
assert_file_contains "$CLAUDE_DIR/commands/catchup.md" "Custom Catchup Preamble" "Extend still custom after partial cleanup"

# ============================================
# Multiple markers in one file
# ============================================

scenario "Multiple base markers in one file (all resolved)"

assert_file_exists "$CLAUDE_DIR/commands/test-multi.md" "test-multi.md installed"
if grep -q '{{base:' "$CLAUDE_DIR/commands/test-multi.md" 2>/dev/null; then
    fail "Multiple markers not fully resolved"
else
    pass "All markers resolved"
fi
# Both base contents should be present (file should be large)
multi_words=$(wc -w < "$CLAUDE_DIR/commands/test-multi.md")
if (( multi_words > 100 )); then
    pass "Multiple base contents merged ($multi_words words)"
else
    fail "Multiple base contents not merged (only $multi_words words)"
fi

# ============================================
# Summary
# ============================================

print_summary

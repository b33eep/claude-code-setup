#!/bin/bash

# Scenario: --remove-custom flag removes the entire custom repo and all artifacts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

setup_test_env
trap cleanup_test_env EXIT

# ============================================
# Setup custom repo with skills, MCP, command override, script
# ============================================

mkdir -p "$CUSTOM_DIR/.git"
mkdir -p "$CUSTOM_DIR/mcp"
mkdir -p "$CUSTOM_DIR/skills/my-skill"
mkdir -p "$CUSTOM_DIR/commands"
mkdir -p "$CUSTOM_DIR/scripts"

cat > "$CUSTOM_DIR/skills/my-skill/SKILL.md" << 'EOF'
---
name: my-skill
description: Test custom skill
type: context
applies_to: [test]
---
# My Skill
EOF

cat > "$CUSTOM_DIR/mcp/my-mcp.json" << 'EOF'
{
  "name": "my-mcp",
  "description": "Test MCP server",
  "config": {
    "type": "stdio",
    "command": "echo",
    "args": ["test"]
  },
  "requiresApiKey": false
}
EOF

# Override of a base command (catchup.md exists in base)
cat > "$CUSTOM_DIR/commands/catchup.md" << 'EOF'
# Custom Catchup Override
This replaces the base catchup command.
EOF

# Custom-only command (no base counterpart)
cat > "$CUSTOM_DIR/commands/my-cmd.md" << 'EOF'
# My Custom Command
EOF

# Custom script
cat > "$CUSTOM_DIR/scripts/helper.sh" << 'EOF'
#!/bin/bash
echo "helper"
EOF
chmod +x "$CUSTOM_DIR/scripts/helper.sh"

# ============================================
# Install with custom modules registered
# ============================================

run_install_expect '
    confirm_mcp
    confirm_skills
    decline_statusline
    decline_agent_teams
' > /dev/null

# Register custom modules
HOME="$TEST_DIR" \
CLAUDE_DIR="$CLAUDE_DIR" \
CUSTOM_DIR="$CUSTOM_DIR" \
MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
INSTALLED_FILE="$INSTALLED_FILE" \
SKIP_SKILL_DEPS=1 \
"$PROJECT_DIR/install.sh" --add-skill custom:my-skill > /dev/null 2>&1

HOME="$TEST_DIR" \
CLAUDE_DIR="$CLAUDE_DIR" \
CUSTOM_DIR="$CUSTOM_DIR" \
MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
INSTALLED_FILE="$INSTALLED_FILE" \
"$PROJECT_DIR/install.sh" --add-mcp custom:my-mcp > /dev/null 2>&1

# Simulate /add-custom tracking (custom_url + custom_version)
jq '.custom_url = "git@example.com:test/repo.git" | .custom_version = 1 |
    .command_overrides = ["catchup.md", "my-cmd.md"] |
    .scripts = ["helper.sh"]' \
    "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp" && mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"

# Materialise the override + custom script on disk (mirrors install_custom_commands/scripts)
cp "$CUSTOM_DIR/commands/catchup.md" "$CLAUDE_DIR/commands/catchup.md"
cp "$CUSTOM_DIR/commands/my-cmd.md" "$CLAUDE_DIR/commands/my-cmd.md"
mkdir -p "$CLAUDE_DIR/scripts"
cp "$CUSTOM_DIR/scripts/helper.sh" "$CLAUDE_DIR/scripts/helper.sh"
chmod +x "$CLAUDE_DIR/scripts/helper.sh"

# ============================================
# Verify initial state
# ============================================

scenario "Initial setup verified"

assert_dir_exists "$CUSTOM_DIR" "custom dir exists"
assert_dir_exists "$CLAUDE_DIR/skills/my-skill" "custom skill installed"
assert_json_exists "$MCP_CONFIG_FILE" '.mcpServers["my-mcp"]' "my-mcp in .claude.json"
assert_json_exists "$INSTALLED_FILE" '.skills | index("custom:my-skill")' "custom:my-skill tracked"
assert_json_exists "$INSTALLED_FILE" '.mcp | index("custom:my-mcp")' "custom:my-mcp tracked"
assert_file_contains "$CLAUDE_DIR/commands/catchup.md" "Custom Catchup Override" "catchup overridden"
assert_file_exists "$CLAUDE_DIR/commands/my-cmd.md" "custom-only command installed"
assert_file_exists "$CLAUDE_DIR/scripts/helper.sh" "custom script installed"
assert_json_eq "$INSTALLED_FILE" '.custom_url' "git@example.com:test/repo.git" "custom_url set"

# ============================================
# Run --remove-custom
# ============================================

REMOVE_RC=0
REMOVE_OUTPUT=$(HOME="$TEST_DIR" \
CLAUDE_DIR="$CLAUDE_DIR" \
CUSTOM_DIR="$CUSTOM_DIR" \
MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
INSTALLED_FILE="$INSTALLED_FILE" \
SKIP_SKILL_DEPS=1 \
SKIP_EXTERNAL_PLUGINS=1 \
"$PROJECT_DIR/install.sh" --remove-custom 2>&1) || REMOVE_RC=$?

if [[ $REMOVE_RC -eq 0 ]]; then
    pass "--remove-custom exited 0"
else
    fail "--remove-custom exited with rc=$REMOVE_RC (output: $REMOVE_OUTPUT)"
fi

# ============================================
# Assertions
# ============================================

scenario "Custom skill removed"

if [[ -d "$CLAUDE_DIR/skills/my-skill" ]]; then
    fail "custom skill directory should be gone"
else
    pass "custom skill directory removed"
fi

if jq -e '.skills[] | select(. == "custom:my-skill")' "$INSTALLED_FILE" > /dev/null 2>&1; then
    fail "custom:my-skill should be untracked"
else
    pass "custom:my-skill untracked"
fi

scenario "Custom MCP removed"

if jq -e '.mcpServers["my-mcp"]' "$MCP_CONFIG_FILE" > /dev/null 2>&1; then
    fail "my-mcp should be removed from .claude.json"
else
    pass "my-mcp removed from .claude.json"
fi

if jq -e '.mcp[] | select(. == "custom:my-mcp")' "$INSTALLED_FILE" > /dev/null 2>&1; then
    fail "custom:my-mcp should be untracked"
else
    pass "custom:my-mcp untracked"
fi

scenario "Override command restored to base; custom-only command deleted"

# catchup.md is a base command, so the base version should be restored
assert_file_exists "$CLAUDE_DIR/commands/catchup.md" "catchup.md still present"
if grep -q "Custom Catchup Override" "$CLAUDE_DIR/commands/catchup.md" 2>/dev/null; then
    fail "catchup.md should be base version, not custom"
else
    pass "catchup.md restored to base"
fi
# Compare to repo base file
if diff -q "$PROJECT_DIR/commands/catchup.md" "$CLAUDE_DIR/commands/catchup.md" > /dev/null 2>&1; then
    pass "catchup.md matches base from repo"
else
    fail "catchup.md should match base from repo"
fi

if [[ -f "$CLAUDE_DIR/commands/my-cmd.md" ]]; then
    fail "my-cmd.md should be deleted (no base counterpart)"
else
    pass "my-cmd.md deleted"
fi

if jq -e '.command_overrides | length > 0' "$INSTALLED_FILE" > /dev/null 2>&1; then
    fail "command_overrides should be empty"
else
    pass "command_overrides cleared"
fi

scenario "Custom script removed"

if [[ -f "$CLAUDE_DIR/scripts/helper.sh" ]]; then
    fail "helper.sh should be deleted"
else
    pass "helper.sh deleted"
fi

if jq -e '.scripts | length > 0' "$INSTALLED_FILE" > /dev/null 2>&1; then
    fail "scripts should be empty"
else
    pass "scripts cleared"
fi

scenario "Custom repo and tracking fields cleared"

if [[ -d "$CUSTOM_DIR" ]]; then
    fail "$CUSTOM_DIR should be deleted"
else
    pass "$CUSTOM_DIR deleted"
fi

if jq -e '.custom_url' "$INSTALLED_FILE" > /dev/null 2>&1; then
    fail "custom_url should be removed from installed.json"
else
    pass "custom_url removed"
fi

if jq -e '.custom_version' "$INSTALLED_FILE" > /dev/null 2>&1; then
    fail "custom_version should be removed from installed.json"
else
    pass "custom_version removed"
fi

scenario "Output reports counts and CLAUDE.md rebuild"

if echo "$REMOVE_OUTPUT" | grep -q "Removing Custom Repo"; then
    pass "output shows progress header"
else
    fail "output should show progress header"
fi

if echo "$REMOVE_OUTPUT" | grep -q "Rebuilding CLAUDE.md"; then
    pass "output mentions CLAUDE.md rebuild"
else
    fail "output should mention CLAUDE.md rebuild"
fi

if echo "$REMOVE_OUTPUT" | grep -q "Restart Claude Code"; then
    pass "output reminds to restart Claude Code (MCP removed)"
else
    fail "output should remind to restart Claude Code"
fi

scenario "CLAUDE.md no longer references removed custom modules"

if grep -q "my-skill" "$CLAUDE_DIR/CLAUDE.md" 2>/dev/null; then
    fail "CLAUDE.md should not reference my-skill"
else
    pass "CLAUDE.md cleaned of my-skill"
fi

if grep -q "my-mcp" "$CLAUDE_DIR/CLAUDE.md" 2>/dev/null; then
    fail "CLAUDE.md should not reference my-mcp"
else
    pass "CLAUDE.md cleaned of my-mcp"
fi

# ============================================
# Scenario: idempotent re-run
# ============================================

scenario "Re-running --remove-custom is idempotent"

REMOVE_RC2=0
REMOVE_OUTPUT2=$(HOME="$TEST_DIR" \
CLAUDE_DIR="$CLAUDE_DIR" \
CUSTOM_DIR="$CUSTOM_DIR" \
MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
INSTALLED_FILE="$INSTALLED_FILE" \
SKIP_SKILL_DEPS=1 \
SKIP_EXTERNAL_PLUGINS=1 \
"$PROJECT_DIR/install.sh" --remove-custom 2>&1) || REMOVE_RC2=$?

if [[ $REMOVE_RC2 -eq 0 ]]; then
    pass "idempotent re-run exited 0"
else
    fail "idempotent re-run exited with rc=$REMOVE_RC2"
fi

if echo "$REMOVE_OUTPUT2" | grep -q "No custom repo registered"; then
    pass "second run reports nothing to remove"
else
    fail "second run should report nothing to remove (output: $REMOVE_OUTPUT2)"
fi

# ============================================
# Scenario: partial state (tracking present, custom dir missing)
# ============================================

scenario "Partial state: tracking exists but custom dir missing"

# Add tracking back without recreating $CUSTOM_DIR
jq '.custom_url = "git@example.com:test/repo.git" |
    .custom_version = 1 |
    .skills = (.skills + ["custom:ghost-skill"])' \
    "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp" && mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"

REMOVE_RC3=0
REMOVE_OUTPUT3=$(HOME="$TEST_DIR" \
CLAUDE_DIR="$CLAUDE_DIR" \
CUSTOM_DIR="$CUSTOM_DIR" \
MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
INSTALLED_FILE="$INSTALLED_FILE" \
SKIP_SKILL_DEPS=1 \
SKIP_EXTERNAL_PLUGINS=1 \
"$PROJECT_DIR/install.sh" --remove-custom 2>&1) || REMOVE_RC3=$?

if [[ $REMOVE_RC3 -eq 0 ]]; then
    pass "partial-state run exited 0"
else
    fail "partial-state run exited with rc=$REMOVE_RC3"
fi

if jq -e '.custom_url' "$INSTALLED_FILE" > /dev/null 2>&1; then
    fail "custom_url should still be cleared in partial state"
else
    pass "custom_url cleared in partial state"
fi

if jq -e '.skills[] | select(. == "custom:ghost-skill")' "$INSTALLED_FILE" > /dev/null 2>&1; then
    fail "custom:ghost-skill should be untracked even without skill dir"
else
    pass "custom:ghost-skill untracked in partial state"
fi

# Output should not crash; it may warn that the skill directory was not found
if echo "$REMOVE_OUTPUT3" | grep -q "Removing Custom Repo"; then
    pass "partial state still runs through removal flow"
else
    fail "partial state should still run removal flow (output: $REMOVE_OUTPUT3)"
fi

# ============================================
# Scenario: installed.json missing entirely
# ============================================

scenario "Missing installed.json: early-return path"

rm -f "$INSTALLED_FILE"

REMOVE_RC4=0
REMOVE_OUTPUT4=$(HOME="$TEST_DIR" \
CLAUDE_DIR="$CLAUDE_DIR" \
CUSTOM_DIR="$CUSTOM_DIR" \
MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
INSTALLED_FILE="$INSTALLED_FILE" \
SKIP_SKILL_DEPS=1 \
SKIP_EXTERNAL_PLUGINS=1 \
"$PROJECT_DIR/install.sh" --remove-custom 2>&1) || REMOVE_RC4=$?

if [[ $REMOVE_RC4 -eq 0 ]]; then
    pass "missing installed.json exits 0"
else
    fail "missing installed.json should exit 0 (rc=$REMOVE_RC4)"
fi

if echo "$REMOVE_OUTPUT4" | grep -q "No installation found"; then
    pass "missing installed.json shows correct message"
else
    fail "missing installed.json should say 'No installation found' (output: $REMOVE_OUTPUT4)"
fi

if [[ -f "$INSTALLED_FILE" ]]; then
    fail "installed.json should not be recreated"
else
    pass "installed.json not recreated"
fi

# ============================================
# Summary
# ============================================

print_summary

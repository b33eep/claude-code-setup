#!/bin/bash

# Scenario: --refresh-custom flag refreshes skills, discovers new modules

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

setup_test_env
trap cleanup_test_env EXIT

# ============================================
# Setup custom repo with initial skill + MCP
# ============================================

mkdir -p "$CUSTOM_DIR/.git"
mkdir -p "$CUSTOM_DIR/mcp"
mkdir -p "$CUSTOM_DIR/skills/my-skill"

cat > "$CUSTOM_DIR/skills/my-skill/SKILL.md" << 'EOF'
---
name: my-skill
description: Test skill v1
type: context
applies_to: [test]
---
# My Skill v1
Original content.
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

# ============================================
# Fresh install with custom skill + MCP
# ============================================

# Install selects: toggle custom MCP on (position depends on available MCPs)
# Simpler approach: install with defaults, then manually add custom modules
run_install_expect '
    confirm_mcp
    confirm_skills
    decline_statusline
    decline_agent_teams
' > /dev/null

# Manually register custom modules (simulates initial --add-mcp/--add-skill)
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

# Verify initial state
scenario "Initial setup verified"

assert_file_contains "$CLAUDE_DIR/skills/my-skill/SKILL.md" "My Skill v1" "Initial skill content installed"
assert_json_exists "$INSTALLED_FILE" '.mcp | index("custom:my-mcp")' "custom:my-mcp tracked"
assert_json_exists "$INSTALLED_FILE" '.skills | index("custom:my-skill")' "custom:my-skill tracked"
assert_json_exists "$MCP_CONFIG_FILE" '.mcpServers["my-mcp"]' "my-mcp in .claude.json"

# ============================================
# Simulate git pull: modify + add new modules
# ============================================

# 1. Update existing skill content
cat > "$CUSTOM_DIR/skills/my-skill/SKILL.md" << 'EOF'
---
name: my-skill
description: Test skill v2
type: context
applies_to: [test]
---
# My Skill v2
Updated content after pull.
EOF

# 2. Add new custom skill
mkdir -p "$CUSTOM_DIR/skills/new-skill"
cat > "$CUSTOM_DIR/skills/new-skill/SKILL.md" << 'EOF'
---
name: new-skill
description: Brand new skill
type: context
applies_to: [test]
---
# New Skill
EOF

# 3. Add new custom MCP (no API key)
cat > "$CUSTOM_DIR/mcp/new-mcp.json" << 'EOF'
{
  "name": "new-mcp",
  "description": "New MCP server",
  "config": {
    "type": "stdio",
    "command": "echo",
    "args": ["new"]
  },
  "requiresApiKey": false
}
EOF

# 4. Add MCP that requires API key
cat > "$CUSTOM_DIR/mcp/key-mcp.json" << 'EOF'
{
  "name": "key-mcp",
  "description": "MCP needing API key",
  "config": {
    "type": "stdio",
    "command": "echo",
    "args": ["key"],
    "env": {
      "API_KEY": "{{API_KEY}}"
    }
  },
  "requiresApiKey": true,
  "apiKeyName": "API_KEY",
  "apiKeyPrompt": "Enter API key",
  "apiKeyInstructions": ["Get key from example.com"]
}
EOF

# 5. Track a skill whose source was removed (simulates deleted custom skill)
jq '.skills += ["custom:gone-skill"]' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp" && mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"

# ============================================
# Run --refresh-custom
# ============================================

REFRESH_OUTPUT=$(HOME="$TEST_DIR" \
CLAUDE_DIR="$CLAUDE_DIR" \
CUSTOM_DIR="$CUSTOM_DIR" \
MCP_CONFIG_FILE="$MCP_CONFIG_FILE" \
INSTALLED_FILE="$INSTALLED_FILE" \
SKIP_SKILL_DEPS=1 \
SKIP_EXTERNAL_PLUGINS=1 \
"$PROJECT_DIR/install.sh" --refresh-custom 2>&1) || true

# ============================================
# Assertions
# ============================================

scenario "Refresh updates existing custom skill"

assert_file_contains "$CLAUDE_DIR/skills/my-skill/SKILL.md" "My Skill v2" "Skill content updated to v2"
assert_file_contains "$CLAUDE_DIR/skills/my-skill/SKILL.md" "Updated content after pull" "New content present"
if grep -q "My Skill v1" "$CLAUDE_DIR/skills/my-skill/SKILL.md" 2>/dev/null; then
    fail "Old v1 content should be gone"
else
    pass "Old v1 content removed"
fi

scenario "New custom skill auto-installed"

assert_dir_exists "$CLAUDE_DIR/skills/new-skill" "new-skill directory created"
assert_file_exists "$CLAUDE_DIR/skills/new-skill/SKILL.md" "new-skill SKILL.md exists"
assert_json_exists "$INSTALLED_FILE" '.skills | index("custom:new-skill")' "custom:new-skill tracked in installed.json"

scenario "New custom MCP (no API key) auto-installed"

assert_json_exists "$INSTALLED_FILE" '.mcp | index("custom:new-mcp")' "custom:new-mcp tracked in installed.json"
assert_json_exists "$MCP_CONFIG_FILE" '.mcpServers["new-mcp"]' "new-mcp config in .claude.json"

scenario "MCP with API key is skipped"

if jq -e '.mcp | index("custom:key-mcp")' "$INSTALLED_FILE" > /dev/null 2>&1; then
    fail "custom:key-mcp should NOT be tracked"
else
    pass "custom:key-mcp not tracked in installed.json"
fi
if jq -e '.mcpServers["key-mcp"]' "$MCP_CONFIG_FILE" > /dev/null 2>&1; then
    fail "key-mcp should NOT be in .claude.json"
else
    pass "key-mcp not in .claude.json"
fi
if echo "$REFRESH_OUTPUT" | grep -q "requires API key"; then
    pass "Output warns about API key requirement"
else
    fail "Output should warn about API key requirement"
fi

scenario "CLAUDE.md rebuilt with new modules"

assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "new-mcp" "CLAUDE.md contains new-mcp"
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "new-skill" "CLAUDE.md contains new-skill"

scenario "Missing skill source handled gracefully"

if echo "$REFRESH_OUTPUT" | grep -q "gone-skill"; then
    pass "Output mentions gone-skill"
else
    fail "Output should mention gone-skill"
fi
if echo "$REFRESH_OUTPUT" | grep -q "source not found"; then
    pass "Output warns about missing source"
else
    fail "Output should warn about missing source"
fi

# ============================================
# Summary
# ============================================

print_summary

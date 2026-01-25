#!/bin/bash

# Scenario: skill-creator command skill

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

SKILL_FILE="$PROJECT_DIR/skills/skill-creator/SKILL.md"

scenario "skill-creator SKILL.md exists and has correct format"

assert_file_exists "$SKILL_FILE" "SKILL.md exists"

# Check frontmatter fields
if grep -q "^name: skill-creator$" "$SKILL_FILE"; then
    pass "Has name field"
else
    fail "Missing or incorrect name field"
fi

if grep -q "^type: command$" "$SKILL_FILE"; then
    pass "Has type: command"
else
    fail "Missing or incorrect type field (should be 'command')"
fi

if grep -q "^description:" "$SKILL_FILE"; then
    pass "Has description field"
else
    fail "Missing description field"
fi

# Should NOT have applies_to in frontmatter (command skills don't need it)
# Extract frontmatter (between first two ---) and check
frontmatter=$(sed -n '1,/^---$/p' "$SKILL_FILE" | tail -n +2)
if echo "$frontmatter" | grep -q "^applies_to:"; then
    fail "Command skill should not have applies_to in frontmatter"
else
    pass "No applies_to in frontmatter (correct for command skill)"
fi

scenario "skill-creator content has required sections"

if grep -q "## Overview" "$SKILL_FILE"; then
    pass "Has Overview section"
else
    fail "Missing Overview section"
fi

if grep -q "## Creation Flow" "$SKILL_FILE"; then
    pass "Has Creation Flow section"
else
    fail "Missing Creation Flow section"
fi

if grep -q '\~/.claude/custom/skills' "$SKILL_FILE"; then
    pass "References custom skills location"
else
    fail "Should reference ~/.claude/custom/skills"
fi

if grep -q "type: command" "$SKILL_FILE" && grep -q "type: context" "$SKILL_FILE"; then
    pass "Documents both skill types"
else
    fail "Should document both command and context skill types"
fi

scenario "skill-creator can be installed"

# Fresh install with skill-creator
# MCP: none, Skills: 2=skill-creator, Status line: n
printf 'none\n2\nn\n' | "$PROJECT_DIR/install.sh" > /dev/null

assert_dir_exists "$CLAUDE_DIR/skills/skill-creator" "skill-creator installed"
assert_file_exists "$CLAUDE_DIR/skills/skill-creator/SKILL.md" "SKILL.md installed"
assert_json_exists "$INSTALLED_FILE" '.skills[] | select(. == "skill-creator")' "skill-creator tracked in installed.json"

# Verify content matches source
expected=$(shasum -a 256 "$PROJECT_DIR/skills/skill-creator/SKILL.md" | cut -d' ' -f1)
actual=$(shasum -a 256 "$CLAUDE_DIR/skills/skill-creator/SKILL.md" | cut -d' ' -f1)
if [ "$expected" = "$actual" ]; then
    pass "SKILL.md matches source"
else
    fail "SKILL.md differs from source"
fi

scenario "skill-creator appears in --list after installation"

output=$("$PROJECT_DIR/install.sh" --list 2>&1)

if echo "$output" | grep -q "skill-creator"; then
    pass "skill-creator appears in --list"
else
    fail "skill-creator should appear in --list"
fi

# Print summary
print_summary

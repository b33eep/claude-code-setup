#!/bin/bash

# Scenario: user-stories skill installation and verification

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

scenario "user-stories skill file structure"

# Verify SKILL.md exists in source
assert_file_exists "$PROJECT_DIR/skills/user-stories/SKILL.md" "SKILL.md exists in source"

# Verify SKILL.md has valid YAML front matter
if head -1 "$PROJECT_DIR/skills/user-stories/SKILL.md" | grep -q '^---$'; then
    pass "SKILL.md has YAML front matter"
else
    fail "SKILL.md should start with YAML front matter (---)"
fi

# Verify required YAML fields
skill_name=$(awk '/^name:/ {print $2; exit}' "$PROJECT_DIR/skills/user-stories/SKILL.md")
skill_type=$(awk '/^type:/ {print $2; exit}' "$PROJECT_DIR/skills/user-stories/SKILL.md")

if [[ "$skill_name" == "user-stories" ]]; then
    pass "Skill name is user-stories"
else
    fail "Skill name should be user-stories, got: $skill_name"
fi

if [[ "$skill_type" == "command" ]]; then
    pass "Skill type is command"
else
    fail "Skill type should be command, got: $skill_type"
fi

# Verify source attribution
assert_file_contains "$PROJECT_DIR/skills/user-stories/SKILL.md" "alirezarezvani" "Has source attribution"
assert_file_contains "$PROJECT_DIR/skills/user-stories/SKILL.md" "MIT" "Has MIT license mention"

scenario "user-stories skill content"

# Core sections
assert_file_contains "$PROJECT_DIR/skills/user-stories/SKILL.md" "## User Story Template" "Has story template"
assert_file_contains "$PROJECT_DIR/skills/user-stories/SKILL.md" "## Story Types" "Has story types"
assert_file_contains "$PROJECT_DIR/skills/user-stories/SKILL.md" "## Persona Reference" "Has persona reference"
assert_file_contains "$PROJECT_DIR/skills/user-stories/SKILL.md" "## INVEST Criteria" "Has INVEST criteria"
assert_file_contains "$PROJECT_DIR/skills/user-stories/SKILL.md" "Given-When-Then" "Has Given-When-Then pattern"
assert_file_contains "$PROJECT_DIR/skills/user-stories/SKILL.md" "## Acceptance Criteria" "Has acceptance criteria"
assert_file_contains "$PROJECT_DIR/skills/user-stories/SKILL.md" "AC Checklist" "Has AC checklist"

# Additional sections from templates
assert_file_contains "$PROJECT_DIR/skills/user-stories/SKILL.md" "INVEST Failure Patterns" "Has failure patterns"
assert_file_contains "$PROJECT_DIR/skills/user-stories/SKILL.md" "Story Splitting" "Has story splitting"
assert_file_contains "$PROJECT_DIR/skills/user-stories/SKILL.md" "Common Antipatterns" "Has antipatterns"

# Out of scope content should NOT be present
if grep -q "Sprint Planning" "$PROJECT_DIR/skills/user-stories/SKILL.md" 2>/dev/null; then
    fail "Should NOT contain sprint planning (out of scope)"
else
    pass "No sprint planning content (correctly scoped)"
fi

if grep -q "Velocity" "$PROJECT_DIR/skills/user-stories/SKILL.md" 2>/dev/null; then
    fail "Should NOT contain velocity tracking (out of scope)"
else
    pass "No velocity tracking content (correctly scoped)"
fi

if grep -q "Epic Breakdown" "$PROJECT_DIR/skills/user-stories/SKILL.md" 2>/dev/null; then
    fail "Should NOT contain epic breakdown (out of scope)"
else
    pass "No epic breakdown content (correctly scoped)"
fi

scenario "user-stories skill installation"

# Run install with all skills (default selection)
run_install_expect '
    # MCP: just confirm defaults
    confirm_mcp

    # Skills: confirm defaults (all pre-selected)
    confirm_skills

    # Accept status line
    accept_statusline

    # Decline Agent Teams
    decline_agent_teams
' > /dev/null 2>&1

# Verify skill directory was created
assert_dir_exists "$CLAUDE_DIR/skills/user-stories" "user-stories skill directory created"
assert_file_exists "$CLAUDE_DIR/skills/user-stories/SKILL.md" "SKILL.md installed"

# Verify installed SKILL.md matches source
expected=$(sha256_file "$PROJECT_DIR/skills/user-stories/SKILL.md")
actual=$(sha256_file "$CLAUDE_DIR/skills/user-stories/SKILL.md")
if [[ "$expected" = "$actual" ]]; then
    pass "SKILL.md matches source"
else
    fail "SKILL.md differs from source"
fi

scenario "user-stories tracking in installed.json"

# Verify skill is recorded in installed.json
if jq -e '.skills | index("user-stories")' "$INSTALLED_FILE" > /dev/null 2>&1; then
    pass "user-stories recorded in installed.json"
else
    fail "user-stories not in installed.json"
fi

scenario "user-stories no dependencies"

# Verify no deps.json (user-stories has no external dependencies)
if [[ -f "$PROJECT_DIR/skills/user-stories/deps.json" ]]; then
    fail "user-stories should not have deps.json (no dependencies)"
else
    pass "No deps.json (no dependencies required)"
fi

scenario "/design integration"

# Verify design.md references user-stories skill
assert_file_contains "$PROJECT_DIR/commands/design.md" "user-stories" "/design references user-stories skill"
assert_file_contains "$PROJECT_DIR/commands/design.md" "INVEST" "/design mentions INVEST criteria"

# Print summary
print_summary

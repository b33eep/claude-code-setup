#!/bin/bash

# Scenario: standards-java skill installation and verification

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

scenario "standards-java skill file structure"

# Verify SKILL.md exists in source
assert_file_exists "$PROJECT_DIR/skills/standards-java/SKILL.md" "SKILL.md exists in source"

# Verify SKILL.md has valid YAML front matter
if head -1 "$PROJECT_DIR/skills/standards-java/SKILL.md" | grep -q '^---$'; then
    pass "SKILL.md has YAML front matter"
else
    fail "SKILL.md should start with YAML front matter (---)"
fi

# Verify required YAML fields
skill_name=$(awk '/^name:/ {print $2; exit}' "$PROJECT_DIR/skills/standards-java/SKILL.md")
skill_type=$(awk '/^type:/ {print $2; exit}' "$PROJECT_DIR/skills/standards-java/SKILL.md")

if [[ "$skill_name" == "standards-java" ]]; then
    pass "Skill name is standards-java"
else
    fail "Skill name should be standards-java, got: $skill_name"
fi

if [[ "$skill_type" == "context" ]]; then
    pass "Skill type is context"
else
    fail "Skill type should be context, got: $skill_type"
fi

# Verify applies_to field includes java
if grep -q 'applies_to:.*java' "$PROJECT_DIR/skills/standards-java/SKILL.md"; then
    pass "applies_to includes java"
else
    fail "applies_to should include java"
fi

scenario "standards-java skill content sections"

# Verify key sections exist
sections=(
    "Core Principles"
    "Naming Conventions"
    "Modern Java Features"
    "Code Organization"
    "Exception Handling"
    "Collections & Streams API"
    "Optional & Null Handling"
    "Testing Fundamentals"
    "Build Tool Awareness"
    "Recommended Tooling"
    "Production Best Practices"
)

for section in "${sections[@]}"; do
    if grep -q "## $section" "$PROJECT_DIR/skills/standards-java/SKILL.md"; then
        pass "Section: $section"
    else
        fail "Missing section: $section"
    fi
done

# Verify modern Java features are covered
modern_features=(
    "records"
    "sealed classes"
    "pattern matching"
    "text blocks"
    "switch expressions"
)

for feature in "${modern_features[@]}"; do
    if grep -iq "$feature" "$PROJECT_DIR/skills/standards-java/SKILL.md"; then
        pass "Modern Java feature: $feature"
    else
        fail "Missing modern Java feature: $feature"
    fi
done

scenario "standards-java skill installation"

# Run install with all skills (default selection)
# standards-java should be automatically discovered and available
run_install_expect '
    # MCP: just confirm defaults
    confirm_mcp

    # Skills: confirm defaults (all pre-selected)
    confirm_skills

    # Accept status line
    accept_statusline
' > /dev/null 2>&1

# Verify skill directory was created
assert_dir_exists "$CLAUDE_DIR/skills/standards-java" "standards-java skill directory created"
assert_file_exists "$CLAUDE_DIR/skills/standards-java/SKILL.md" "SKILL.md installed"

# Verify installed SKILL.md matches source
expected=$(sha256_file "$PROJECT_DIR/skills/standards-java/SKILL.md")
actual=$(sha256_file "$CLAUDE_DIR/skills/standards-java/SKILL.md")
if [[ "$expected" = "$actual" ]]; then
    pass "SKILL.md matches source"
else
    fail "SKILL.md differs from source"
fi

scenario "standards-java tracking in installed.json"

# Verify skill is recorded in installed.json
if jq -e '.skills | index("standards-java")' "$INSTALLED_FILE" > /dev/null 2>&1; then
    pass "standards-java recorded in installed.json"
else
    fail "standards-java not in installed.json"
fi

scenario "standards-java auto-loading metadata"

# Verify applies_to field for auto-loading
applies_to_line=$(grep -A1 '^applies_to:' "$CLAUDE_DIR/skills/standards-java/SKILL.md" | tr -d '\n')

# Check for key Java ecosystem keywords
keywords=("java" "maven" "gradle" "junit" "spring")
for keyword in "${keywords[@]}"; do
    if echo "$applies_to_line" | grep -q "$keyword"; then
        pass "applies_to includes $keyword"
    else
        fail "applies_to should include $keyword"
    fi
done

scenario "standards-java no dependencies"

# Verify no deps.json (standards-java has no external dependencies)
if [[ -f "$PROJECT_DIR/skills/standards-java/deps.json" ]]; then
    fail "standards-java should not have deps.json (no dependencies)"
else
    pass "No deps.json (no dependencies required)"
fi

# Print summary
print_summary

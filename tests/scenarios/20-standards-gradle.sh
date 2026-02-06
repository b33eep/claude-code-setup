#!/bin/bash

# Scenario: standards-gradle context skill

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

SKILL_FILE="$PROJECT_DIR/skills/standards-gradle/SKILL.md"

scenario "standards-gradle SKILL.md exists and has correct format"

assert_file_exists "$SKILL_FILE" "SKILL.md exists"

# Check frontmatter fields
if grep -q "^name: standards-gradle$" "$SKILL_FILE"; then
    pass "Has name field"
else
    fail "Missing or incorrect name field"
fi

if grep -q "^type: context$" "$SKILL_FILE"; then
    pass "Has type: context"
else
    fail "Missing or incorrect type field (should be 'context')"
fi

if grep -q "^description:" "$SKILL_FILE"; then
    pass "Has description field"
else
    fail "Missing description field"
fi

# Should have applies_to with 'gradle' (context skills need this)
if grep -q "^applies_to:.*gradle" "$SKILL_FILE"; then
    pass "Has applies_to with gradle"
else
    fail "Missing or incorrect applies_to field (should include 'gradle')"
fi

scenario "standards-gradle content has required sections"

# Check for main sections
if grep -q "## Core Principles" "$SKILL_FILE"; then
    pass "Has Core Principles section"
else
    fail "Missing Core Principles section"
fi

if grep -q "## Section 1: Project Configuration" "$SKILL_FILE"; then
    pass "Has Section 1: Project Configuration"
else
    fail "Missing Section 1: Project Configuration"
fi

if grep -q "## Section 2: Plugin/Task Development" "$SKILL_FILE"; then
    pass "Has Section 2: Plugin/Task Development"
else
    fail "Missing Section 2: Plugin/Task Development"
fi

if grep -q "## Groovy → Kotlin DSL Migration Guide" "$SKILL_FILE"; then
    pass "Has Groovy → Kotlin DSL Migration Guide"
else
    fail "Missing Groovy → Kotlin DSL Migration Guide"
fi

# Check for key subsections
if grep -q "### Build Script Basics" "$SKILL_FILE"; then
    pass "Has Build Script Basics subsection"
else
    fail "Missing Build Script Basics subsection"
fi

if grep -q "### Dependency Management" "$SKILL_FILE"; then
    pass "Has Dependency Management subsection"
else
    fail "Missing Dependency Management subsection"
fi

if grep -q "### Custom Tasks" "$SKILL_FILE"; then
    pass "Has Custom Tasks subsection"
else
    fail "Missing Custom Tasks subsection"
fi

if grep -q "### Providers API" "$SKILL_FILE"; then
    pass "Has Providers API subsection"
else
    fail "Missing Providers API subsection"
fi

if grep -q "### Gradle Caching" "$SKILL_FILE"; then
    pass "Has Gradle Caching subsection"
else
    fail "Missing Gradle Caching subsection"
fi

scenario "standards-gradle mentions Gradle 9"

# Should reference Gradle 9 LTS
if grep -q "Gradle 9" "$SKILL_FILE"; then
    pass "References Gradle 9"
else
    fail "Should reference Gradle 9 LTS"
fi

# Should have Kotlin DSL examples (build.gradle.kts)
if grep -q "build.gradle.kts" "$SKILL_FILE"; then
    pass "References build.gradle.kts"
else
    fail "Should reference build.gradle.kts"
fi

# Should have version catalog examples
if grep -q "libs.versions.toml" "$SKILL_FILE"; then
    pass "References version catalogs"
else
    fail "Should reference libs.versions.toml (version catalogs)"
fi

scenario "standards-gradle test project exists"

TEST_PROJECT_DIR="$PROJECT_DIR/skills/standards-gradle/test-project"
assert_dir_exists "$TEST_PROJECT_DIR" "test-project directory exists"
assert_file_exists "$TEST_PROJECT_DIR/build.gradle.kts" "test-project has build.gradle.kts"
assert_file_exists "$TEST_PROJECT_DIR/settings.gradle.kts" "test-project has settings.gradle.kts"
assert_file_exists "$TEST_PROJECT_DIR/README.md" "test-project has README.md"
assert_file_exists "$TEST_PROJECT_DIR/gradlew" "test-project has Gradle wrapper"

# Verify buildSrc exists
assert_dir_exists "$TEST_PROJECT_DIR/buildSrc" "test-project has buildSrc"
assert_file_exists "$TEST_PROJECT_DIR/buildSrc/build.gradle.kts" "buildSrc has build.gradle.kts"

scenario "standards-gradle can be installed"

# Fresh install with only standards-gradle
# Skill order (alphabetical): 1=create-slidev, 2=skill-creator, 3=standards-gradle,
#                             4=standards-java, 5=standards-javascript, 6=standards-kotlin,
#                             7=standards-python, 8=standards-shell, 9=standards-typescript
run_install_expect '
    # Deselect all MCP
    deselect_all_mcp

    # Select only standards-gradle (#3)
    select_only_skill 3

    # Decline status line
    decline_statusline
' > /dev/null

assert_dir_exists "$CLAUDE_DIR/skills/standards-gradle" "standards-gradle installed"
assert_file_exists "$CLAUDE_DIR/skills/standards-gradle/SKILL.md" "SKILL.md installed"
assert_json_exists "$INSTALLED_FILE" '.skills[] | select(. == "standards-gradle")' "standards-gradle tracked in installed.json"

# Verify content matches source
expected=$(sha256_file "$PROJECT_DIR/skills/standards-gradle/SKILL.md")
actual=$(sha256_file "$CLAUDE_DIR/skills/standards-gradle/SKILL.md")
if [ "$expected" = "$actual" ]; then
    pass "SKILL.md matches source"
else
    fail "SKILL.md differs from source"
fi

# Verify test-project is also copied (users can experiment with examples)
assert_dir_exists "$CLAUDE_DIR/skills/standards-gradle/test-project" "test-project installed"

scenario "standards-gradle appears in --list after installation"

output=$("$PROJECT_DIR/install.sh" --list 2>&1)

if echo "$output" | grep -q "standards-gradle"; then
    pass "standards-gradle appears in --list"
else
    fail "standards-gradle should appear in --list"
fi

scenario "test project builds successfully"

if java -version &>/dev/null; then
    # Run gradle build in test project to validate examples compile
    cd "$TEST_PROJECT_DIR" || exit 1

    # Test 1: Basic build
    if ./gradlew build --no-daemon --quiet 2>&1; then
        pass "test project builds successfully"
    else
        fail "test project build failed"
    fi

    # Test 2: Custom tasks execute
    if ./gradlew exampleTask --no-daemon --quiet 2>&1 | grep -q "Example task executed"; then
        pass "custom task executes"
    else
        fail "custom task failed to execute"
    fi

    # Test 3: Cacheable task works
    if ./gradlew cacheableTask --no-daemon --quiet 2>&1; then
        pass "cacheable task executes"
    else
        fail "cacheable task failed"
    fi

    # Test 4: Version catalog works (libs.* accessors compile)
    if ./gradlew dependencies --no-daemon --quiet 2>&1 | grep -q "guava"; then
        pass "version catalog dependencies resolved"
    else
        fail "version catalog dependencies not found"
    fi

    cd - > /dev/null || exit 1
else
    pass "test project builds successfully (skipped - no Java)"
    pass "custom task executes (skipped - no Java)"
    pass "cacheable task executes (skipped - no Java)"
    pass "version catalog dependencies resolved (skipped - no Java)"
fi

# Print summary
print_summary

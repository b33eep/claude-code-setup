#!/bin/bash

# Scenario: Preserve user instructions in global CLAUDE.md during updates

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

scenario "Fresh install has User Instructions section"

# Fresh install with minimal options
run_install_expect '
    deselect_all_mcp
    deselect_all_skills
    decline_statusline
' > /dev/null

# Verify markers exist
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "<!-- USER INSTRUCTIONS START -->" "START marker exists"
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "<!-- USER INSTRUCTIONS END -->" "END marker exists"
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "## User Instructions" "User Instructions heading exists"

scenario "Default placeholder content present"

assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "Add your personal instructions" "Default placeholder text present"

scenario "Update preserves custom user content"

# Add custom content between markers
sed -i.bak 's/Add your personal instructions.*/MY CUSTOM INSTRUCTION: Always respond in German/' "$CLAUDE_DIR/CLAUDE.md"
rm -f "$CLAUDE_DIR/CLAUDE.md.bak"

# Verify custom content was added
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "MY CUSTOM INSTRUCTION" "Custom content added successfully"

# Set lower version to trigger update
jq '.content_version = 0' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp" && mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"

# Run update
"$PROJECT_DIR/install.sh" --update --yes > /dev/null 2>&1

# Verify custom content is preserved
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "MY CUSTOM INSTRUCTION: Always respond in German" "Custom content preserved after update"

# Verify markers still exist
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "<!-- USER INSTRUCTIONS START -->" "START marker still exists after update"
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "<!-- USER INSTRUCTIONS END -->" "END marker still exists after update"

scenario "Default placeholder is replaced on update (not preserved)"

# Reset to fresh install
rm -rf "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR"

run_install_expect '
    deselect_all_mcp
    deselect_all_skills
    decline_statusline
' > /dev/null

# Verify default content
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "Add your personal instructions" "Fresh install has default placeholder"

# Set lower version to trigger update
jq '.content_version = 0' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp" && mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"

# Run update (default content should be replaced with new template's default)
"$PROJECT_DIR/install.sh" --update --yes > /dev/null 2>&1

# Verify default content is still there (from new template)
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "Add your personal instructions" "Default placeholder from new template"

scenario "Multi-line custom content preserved"

# Add multi-line custom content by replacing the section in CLAUDE.md
# Use awk to replace content between markers
awk '
    /<!-- USER INSTRUCTIONS START -->/ {
        print "<!-- USER INSTRUCTIONS START -->"
        print "## My Preferences"
        print ""
        print "- Always respond in German"
        print "- Use formal language (Sie)"
        print "- Include code examples"
        print ""
        print "## API Keys Location"
        print ""
        print "See ~/.config/secrets/api-keys.env"
        skip=1
        next
    }
    /<!-- USER INSTRUCTIONS END -->/ {
        skip=0
    }
    !skip { print }
' "$CLAUDE_DIR/CLAUDE.md" > /tmp/claude-modified.md
mv /tmp/claude-modified.md "$CLAUDE_DIR/CLAUDE.md"

# Verify multi-line content
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "Always respond in German" "Multi-line content: line 1"
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "API Keys Location" "Multi-line content: line 2"

# Set lower version and update
jq '.content_version = 0' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp" && mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"
"$PROJECT_DIR/install.sh" --update --yes > /dev/null 2>&1

# Verify all custom content preserved
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "Always respond in German" "Multi-line preserved: line 1"
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "Use formal language" "Multi-line preserved: line 2"
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "API Keys Location" "Multi-line preserved: section header"
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "secrets/api-keys.env" "Multi-line preserved: path"

scenario "Missing markers results in overwrite"

# Remove markers manually (simulate user deleting them)
grep -v "<!-- USER INSTRUCTIONS" "$CLAUDE_DIR/CLAUDE.md" > /tmp/claude-no-markers.md
echo "ORPHANED CONTENT WITHOUT MARKERS" >> /tmp/claude-no-markers.md
mv /tmp/claude-no-markers.md "$CLAUDE_DIR/CLAUDE.md"

# Verify markers are gone
if grep -q "<!-- USER INSTRUCTIONS" "$CLAUDE_DIR/CLAUDE.md"; then
    fail "Markers should be removed for this test"
else
    pass "Markers removed for test"
fi

# Set lower version and update
jq '.content_version = 0' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp" && mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"
"$PROJECT_DIR/install.sh" --update --yes > /dev/null 2>&1

# Verify markers are restored from template
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "<!-- USER INSTRUCTIONS START -->" "Markers restored after update"

# Verify orphaned content is gone (overwritten by template)
if grep -q "ORPHANED CONTENT WITHOUT MARKERS" "$CLAUDE_DIR/CLAUDE.md"; then
    fail "Orphaned content should be overwritten"
else
    pass "Orphaned content overwritten"
fi

scenario "Special characters in user content preserved"

# Add content with special characters using heredoc (safer than awk for special chars)
# First, get content before and after the user section
awk '/<!-- USER INSTRUCTIONS START -->/{exit} {print}' "$CLAUDE_DIR/CLAUDE.md" > /tmp/before-section.md
awk 'p; /<!-- USER INSTRUCTIONS END -->/{p=1}' "$CLAUDE_DIR/CLAUDE.md" > /tmp/after-section.md

# Create new file with special characters in user section
cat /tmp/before-section.md > "$CLAUDE_DIR/CLAUDE.md"
cat >> "$CLAUDE_DIR/CLAUDE.md" << 'SPECIAL_EOF'
<!-- USER INSTRUCTIONS START -->
Path: ~/projects/$USER/config
Pattern: *.txt [a-z]+
Ampersand: foo && bar
Pipe: cat file | grep test
<!-- USER INSTRUCTIONS END -->
SPECIAL_EOF
cat /tmp/after-section.md >> "$CLAUDE_DIR/CLAUDE.md"
rm -f /tmp/before-section.md /tmp/after-section.md

# Verify special chars were added
# shellcheck disable=SC2016  # Intentional: testing literal $USER string
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" 'projects/$USER' "Special chars added: dollar sign"
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" '*.txt' "Special chars added: asterisk"

# Set lower version and update
jq '.content_version = 0' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp" && mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"
"$PROJECT_DIR/install.sh" --update --yes > /dev/null 2>&1

# Verify special characters preserved
# shellcheck disable=SC2016  # Intentional: testing literal $USER string
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" 'projects/$USER' "Special chars preserved: dollar sign"
# Note: grep interprets *.txt as regex, so we test parts separately
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" 'Pattern:' "Special chars preserved: pattern line exists"
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" 'foo && bar' "Special chars preserved: ampersand"
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" 'cat file | grep' "Special chars preserved: pipe"

# Print summary
print_summary

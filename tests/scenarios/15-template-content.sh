#!/bin/bash

# Scenario: Template content validation
# Ensures templates contain expected sections and content

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

# ============================================
# GLOBAL CLAUDE.MD TEMPLATE
# ============================================

scenario "Global CLAUDE.md template structure"

GLOBAL_TEMPLATE="$PROJECT_DIR/templates/base/global-CLAUDE.md"

# Core sections
assert_file_contains "$GLOBAL_TEMPLATE" "## Conventions" "Has Conventions section"
assert_file_contains "$GLOBAL_TEMPLATE" "## Security" "Has Security section"
assert_file_contains "$GLOBAL_TEMPLATE" "## Workflow: Session & Context Management" "Has Workflow section"

# Session workflow
assert_file_contains "$GLOBAL_TEMPLATE" "### Session Start" "Has Session Start"
assert_file_contains "$GLOBAL_TEMPLATE" "### Context Rules" "Has Context Rules"
assert_file_contains "$GLOBAL_TEMPLATE" "/catchup" "References /catchup"
assert_file_contains "$GLOBAL_TEMPLATE" "/wrapup" "References /wrapup"
assert_file_contains "$GLOBAL_TEMPLATE" "/init-project" "References /init-project"

# Development flow
assert_file_contains "$GLOBAL_TEMPLATE" "## Development Flow" "Has Development Flow"
assert_file_contains "$GLOBAL_TEMPLATE" "SPECIFY" "Flow includes SPECIFY"
assert_file_contains "$GLOBAL_TEMPLATE" "IMPLEMENT" "Flow includes IMPLEMENT"

# File structure
assert_file_contains "$GLOBAL_TEMPLATE" "## File Structure: What Goes Where?" "Has File Structure section"
assert_file_contains "$GLOBAL_TEMPLATE" "### Records" "Has Records subsection"

# Recent Decisions workflow (v23)
assert_file_contains "$GLOBAL_TEMPLATE" "### Recent Decisions" "Has Recent Decisions workflow"
assert_file_contains "$GLOBAL_TEMPLATE" "Too small for a Record" "Explains when to add decisions"
assert_file_contains "$GLOBAL_TEMPLATE" "Max 20 entries" "Documents max entries"
assert_file_contains "$GLOBAL_TEMPLATE" "Graduating to Records" "Documents when to graduate to Record"
assert_file_contains "$GLOBAL_TEMPLATE" "Obvious why" "Has negative example for obvious decisions"

# Workflow improvements (v41)
assert_file_contains "$GLOBAL_TEMPLATE" "### After User Corrections" "Has correction persistence trigger"
assert_file_contains "$GLOBAL_TEMPLATE" "Project facts and constraints" "Has correction routing list"
assert_file_contains "$GLOBAL_TEMPLATE" "### Signs to Re-Plan" "Has re-plan signs"
assert_file_contains "$GLOBAL_TEMPLATE" "Third workaround for the same problem" "Has specific re-plan trigger"

# MCP and Skills
assert_file_contains "$GLOBAL_TEMPLATE" "## MCP Servers" "Has MCP Servers section"
assert_file_contains "$GLOBAL_TEMPLATE" "## Skills" "Has Skills section"
assert_file_contains "$GLOBAL_TEMPLATE" "## Skill Loading" "Has Skill Loading section"

# Git conventions
assert_file_contains "$GLOBAL_TEMPLATE" "## Git Commit Messages" "Has Git Commit Messages section"
assert_file_contains "$GLOBAL_TEMPLATE" "No Co-Authored-By" "Has No Co-Authored-By rule"

# Section markers for dynamic table generation
assert_file_contains "$GLOBAL_TEMPLATE" "<!-- USER INSTRUCTIONS START -->" "Has user instructions start marker"
assert_file_contains "$GLOBAL_TEMPLATE" "<!-- USER INSTRUCTIONS END -->" "Has user instructions end marker"
assert_file_contains "$GLOBAL_TEMPLATE" "<!-- MCP_TABLE START -->" "Has MCP table start marker"
assert_file_contains "$GLOBAL_TEMPLATE" "<!-- MCP_TABLE END -->" "Has MCP table end marker"
assert_file_contains "$GLOBAL_TEMPLATE" "<!-- SKILLS_TABLE START -->" "Has skills table start marker"
assert_file_contains "$GLOBAL_TEMPLATE" "<!-- SKILLS_TABLE END -->" "Has skills table end marker"
assert_file_contains "$GLOBAL_TEMPLATE" "<!-- SKILL_LOADING_TABLE START -->" "Has skill loading table start marker"
assert_file_contains "$GLOBAL_TEMPLATE" "<!-- SKILL_LOADING_TABLE END -->" "Has skill loading table end marker"

# ============================================
# PROJECT CLAUDE.MD TEMPLATE
# ============================================

scenario "Project CLAUDE.md template structure"

PROJECT_TEMPLATE="$PROJECT_DIR/templates/project-CLAUDE.md"

# Project template version marker
assert_file_contains "$PROJECT_TEMPLATE" "<!-- project-template:" "Has project-template version marker"

# Marker should be on first line
FIRST_LINE=$(head -1 "$PROJECT_TEMPLATE")
if [[ "$FIRST_LINE" =~ ^\<\!--\ project-template:\ [0-9]+\ --\>$ ]]; then
    pass "Version marker is on first line with valid format"
else
    fail "Version marker should be on first line (got: $FIRST_LINE)"
fi

# Marker version must match VERSION file
MARKER_VERSION=$(echo "$FIRST_LINE" | sed 's/.*project-template: \([0-9]*\).*/\1/')
FILE_VERSION=$(cat "$PROJECT_DIR/templates/VERSION" | tr -d '[:space:]')
if [[ "$MARKER_VERSION" == "$FILE_VERSION" ]]; then
    pass "Project-template marker ($MARKER_VERSION) matches VERSION file ($FILE_VERSION)"
else
    fail "Project-template marker ($MARKER_VERSION) != VERSION ($FILE_VERSION)"
fi

# Header sections
assert_file_contains "$PROJECT_TEMPLATE" "## About" "Has About section"
assert_file_contains "$PROJECT_TEMPLATE" "## Tech Stack" "Has Tech Stack section"

# Status tracking
assert_file_contains "$PROJECT_TEMPLATE" "## Current Status" "Has Current Status section"
assert_file_contains "$PROJECT_TEMPLATE" "| Story | Status | Tests | Notes |" "Has status table header"

# Records table removed (v46)
if grep -q "## Records" "$PROJECT_TEMPLATE" 2>/dev/null; then
    fail "Records section should not exist in project template"
else
    pass "No Records section in project template"
fi

# Future (under Current Status)
assert_file_contains "$PROJECT_TEMPLATE" "### Future" "Has Future subsection"

# Project Instructions
assert_file_contains "$PROJECT_TEMPLATE" "## Project Instructions" "Has Project Instructions section"
assert_file_contains "$PROJECT_TEMPLATE" "<!-- PROJECT INSTRUCTIONS START -->" "Has project instructions start marker"
assert_file_contains "$PROJECT_TEMPLATE" "<!-- PROJECT INSTRUCTIONS END -->" "Has project instructions end marker"

# Files
assert_file_contains "$PROJECT_TEMPLATE" "## Files" "Has Files section"

# Recent Decisions (v23)
assert_file_contains "$PROJECT_TEMPLATE" "## Recent Decisions" "Has Recent Decisions section"
assert_file_contains "$PROJECT_TEMPLATE" "| Date | Decision | Why |" "Has decisions table header"

# Development
assert_file_contains "$PROJECT_TEMPLATE" "## Development" "Has Development section"

# ============================================
# COMMANDS
# ============================================

scenario "Command templates content"

# catchup.md
CATCHUP="$PROJECT_DIR/commands/catchup.md"
assert_file_contains "$CATCHUP" "# Catchup" "catchup.md has title"
assert_file_contains "$CATCHUP" "Check project template version" "catchup checks template version"
assert_file_contains "$CATCHUP" "project-template:" "catchup references project-template marker"
assert_file_contains "$CATCHUP" "CLAUDE.template.md" "catchup reads template file"
assert_file_contains "$CATCHUP" "Read project README.md" "catchup reads README"
assert_file_contains "$CATCHUP" "Read changed files" "catchup reads changed files"
assert_file_contains "$CATCHUP" "Load relevant Records" "catchup loads Records"
assert_file_contains "$CATCHUP" "Check Recent Decisions" "catchup reads Recent Decisions (v23)"
assert_file_contains "$CATCHUP" "Load context skills" "catchup loads skills"
assert_file_contains "$CATCHUP" "migrate-project-template.md" "catchup delegates to migration command"

# migrate-project-template.md
MIGRATE="$PROJECT_DIR/commands/migrate-project-template.md"
assert_file_contains "$MIGRATE" "# Migrate Project Template" "migrate-project-template.md has title"
assert_file_contains "$MIGRATE" "Create backup" "migration creates backup"
assert_file_contains "$MIGRATE" "PROJECT INSTRUCTIONS" "migration preserves Project Instructions"

# wrapup.md
WRAPUP="$PROJECT_DIR/commands/wrapup.md"
assert_file_contains "$WRAPUP" "# Wrapup" "wrapup.md has title"
assert_file_contains "$WRAPUP" "Update CLAUDE.md" "wrapup updates CLAUDE.md"
assert_file_contains "$WRAPUP" "Create Record" "wrapup can create Record"
assert_file_contains "$WRAPUP" "PROJECT INSTRUCTIONS" "wrapup preserves Project Instructions"
assert_file_contains "$WRAPUP" "Git commit" "wrapup handles git"
assert_file_contains "$WRAPUP" "Review for missed decisions" "wrapup reviews missed decisions"

# init-project.md
INIT="$PROJECT_DIR/commands/init-project.md"
assert_file_contains "$INIT" "# Init Project" "init-project.md has title"

# todo.md
TODO="$PROJECT_DIR/commands/todo.md"
assert_file_contains "$TODO" "# Todo" "todo.md has title"

# ============================================
# SKILLS (structure validation)
# ============================================

scenario "Skills structure"

# Check skill directories exist
assert_dir_exists "$PROJECT_DIR/skills/standards-shell" "standards-shell skill exists"
assert_dir_exists "$PROJECT_DIR/skills/standards-python" "standards-python skill exists"
assert_dir_exists "$PROJECT_DIR/skills/standards-javascript" "standards-javascript skill exists"
assert_dir_exists "$PROJECT_DIR/skills/standards-typescript" "standards-typescript skill exists"

# Check SKILL.md files have required frontmatter
for skill in standards-shell standards-python standards-javascript standards-typescript; do
    SKILL_FILE="$PROJECT_DIR/skills/$skill/SKILL.md"
    assert_file_contains "$SKILL_FILE" "name:" "$skill has name in frontmatter"
    assert_file_contains "$SKILL_FILE" "type: context" "$skill is context type"
    assert_file_contains "$SKILL_FILE" "applies_to:" "$skill has applies_to"
    assert_file_contains "$SKILL_FILE" "file_extensions:" "$skill has file_extensions"
done

# ============================================
# VERSION FILE
# ============================================

scenario "Version tracking"

VERSION_FILE="$PROJECT_DIR/templates/VERSION"
assert_file_exists "$VERSION_FILE" "VERSION file exists"

# Version should be a number
VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
if [[ "$VERSION" =~ ^[0-9]+$ ]]; then
    pass "VERSION is numeric ($VERSION)"
else
    fail "VERSION should be numeric (got: $VERSION)"
fi

# Version should be at least 23 (when Recent Decisions was added)
if [[ "$VERSION" -ge 23 ]]; then
    pass "VERSION is at least 23 (current: $VERSION)"
else
    fail "VERSION should be at least 23 (got: $VERSION)"
fi

# Print summary
print_summary

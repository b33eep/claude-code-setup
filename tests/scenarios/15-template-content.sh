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

# User instructions section markers
assert_file_contains "$GLOBAL_TEMPLATE" "<!-- USER INSTRUCTIONS START -->" "Has user instructions start marker"
assert_file_contains "$GLOBAL_TEMPLATE" "<!-- USER INSTRUCTIONS END -->" "Has user instructions end marker"

# ============================================
# PROJECT CLAUDE.MD TEMPLATE
# ============================================

scenario "Project CLAUDE.md template structure"

PROJECT_TEMPLATE="$PROJECT_DIR/templates/project-CLAUDE.md"

# Header sections
assert_file_contains "$PROJECT_TEMPLATE" "## About" "Has About section"
assert_file_contains "$PROJECT_TEMPLATE" "## Tech Stack" "Has Tech Stack section"

# Status tracking
assert_file_contains "$PROJECT_TEMPLATE" "## Current Status" "Has Current Status section"
assert_file_contains "$PROJECT_TEMPLATE" "| Story | Status | Tests | Notes |" "Has status table header"

# Records
assert_file_contains "$PROJECT_TEMPLATE" "## Records" "Has Records section"
assert_file_contains "$PROJECT_TEMPLATE" "| Decision | Choice | Record |" "Has records table header"
assert_file_contains "$PROJECT_TEMPLATE" "### Future" "Has Future subsection"

# Recent Decisions (v23)
assert_file_contains "$PROJECT_TEMPLATE" "## Recent Decisions" "Has Recent Decisions section"
assert_file_contains "$PROJECT_TEMPLATE" "| Date | Decision | Why |" "Has decisions table header"

# User stories and development
assert_file_contains "$PROJECT_TEMPLATE" "## User Stories" "Has User Stories section"
assert_file_contains "$PROJECT_TEMPLATE" "## Development" "Has Development section"

# ============================================
# COMMANDS
# ============================================

scenario "Command templates content"

# catchup.md
CATCHUP="$PROJECT_DIR/commands/catchup.md"
assert_file_contains "$CATCHUP" "# Catchup" "catchup.md has title"
assert_file_contains "$CATCHUP" "Read project README.md" "catchup reads README"
assert_file_contains "$CATCHUP" "Read changed files" "catchup reads changed files"
assert_file_contains "$CATCHUP" "Load relevant Records" "catchup loads Records"
assert_file_contains "$CATCHUP" "Check Recent Decisions" "catchup reads Recent Decisions (v23)"
assert_file_contains "$CATCHUP" "Load context skills" "catchup loads skills"

# wrapup.md
WRAPUP="$PROJECT_DIR/commands/wrapup.md"
assert_file_contains "$WRAPUP" "# Wrapup" "wrapup.md has title"
assert_file_contains "$WRAPUP" "Update CLAUDE.md" "wrapup updates CLAUDE.md"
assert_file_contains "$WRAPUP" "Create Record" "wrapup can create Record"
assert_file_contains "$WRAPUP" "Sync Records table" "wrapup syncs Records"
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

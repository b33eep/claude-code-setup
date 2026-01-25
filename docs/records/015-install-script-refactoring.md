# Record 015: Install Script Refactoring

**Status:** Proposed
**Date:** 2026-01-25

## Context

`install.sh` has grown to 970 lines. Record 006 established the guideline "review at 1000 lines" - we're approaching that threshold.

Current structure (single file):
- Helper functions (lines 44-132)
- Module discovery (lines 160-204)
- List modules (lines 210-300)
- Select modules (lines 306-421)
- Build CLAUDE.md (lines 427-430)
- Install MCP (lines 436-516)
- Install skill (lines 522-545)
- Configure statusline (lines 551-624)
- Main installation (lines 630-749)
- Update installation (lines 755-902)
- Main/CLI parsing (lines 908-968)

## Problem

1. **Navigation difficulty** - Hard to find specific functionality
2. **Testing granularity** - Can't unit test individual functions easily
3. **Maintenance burden** - Changes require understanding entire file
4. **Contribution barrier** - New contributors overwhelmed by file size

## Proposed Solution

### Option A: Source-based Modularization

Split into multiple files, source them from main script:

```
install.sh              # Main entry point (~100 lines)
lib/
├── helpers.sh          # Colors, printing, JSON helpers
├── modules.sh          # Module discovery and selection
├── mcp.sh              # MCP server installation
├── skills.sh           # Skill installation
├── statusline.sh       # ccstatusline configuration
└── update.sh           # Update logic
```

**Pros:**
- Clear separation of concerns
- Easier to test individual components
- Familiar pattern (many bash projects use this)

**Cons:**
- Multiple files to manage
- Need to handle sourcing paths correctly
- ShellCheck needs `-x` flag for all files

### Option B: Keep Single File, Better Organization

Add clear section markers and improve documentation:

```bash
# ============================================
# SECTION: MCP Installation
# ============================================
# Functions: install_mcp, validate_mcp_config
# Dependencies: jq, helpers
# ============================================
```

**Pros:**
- No structural changes
- Single file distribution remains simple
- Works today

**Cons:**
- Doesn't solve testing granularity
- Still grows over time

### Option C: Rewrite in Different Language

Consider Python or Go for better structure.

**Pros:**
- Better tooling (type hints, testing frameworks)
- Easier to maintain long-term

**Cons:**
- Adds runtime dependency
- Complete rewrite effort
- Loses shell integration benefits

## Recommendation

**Option A (Source-based Modularization)** when the script exceeds 1000 lines or when adding Linux support (Record 014), whichever comes first.

Rationale:
- Natural extension of current approach
- Linux support will add ~100-200 lines
- Combined changes justify refactoring

## Decision

**Accepted.** Implemented as part of Linux support work (Record 014).

## Implementation

Created `lib/` directory with the following modules:

```
lib/
├── helpers.sh      # Colors, printing, JSON utilities
├── modules.sh      # Module discovery, selection
├── mcp.sh          # MCP server installation
├── skills.sh       # Skill installation
├── statusline.sh   # ccstatusline configuration
├── update.sh       # Update logic
└── platform.sh     # OS detection, package manager abstraction
```

Main `install.sh` reduced from ~1000 lines to ~300 lines by sourcing these modules.

CI updated with `shellcheck -x` to follow sources.

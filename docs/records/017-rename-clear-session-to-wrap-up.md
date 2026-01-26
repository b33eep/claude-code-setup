# Record 017: Rename /clear-session to /wrapup

**Status:** Done
**Date:** 2025-01-27

## Context

`/clear-session` is misleading - it doesn't clear anything. It documents the current state in CLAUDE.md and commits changes.

## Decision

Rename to `/wrapup` - signifies "wrapping up" the session before clearing. Consistent with `/catchup` (no hyphen).

## Implementation Steps

1. **Rename command file:**
   - `commands/clear-session.md` → `commands/wrapup.md`
   - Update title and description in file

2. **Update global prompt** (`templates/base/global-CLAUDE.md`):
   - Workflow section
   - All references

3. **Update project template** (`templates/project-CLAUDE.md`)

4. **Update README.md:**
   - Workflow diagram
   - Command references

5. **Update Records:**
   - `000-core-workflow.md`
   - `004-document-and-clear-workflow.md`
   - `012-optional-hooks-automation.md`

6. **Update CLAUDE.md:**
   - Records table
   - Status → Done

7. **Version bump:**
   - `templates/VERSION` → v16
   - `CHANGELOG.md` entry

8. **Tests:**
   - `tests/scenarios/01-fresh-install.sh`

9. **Commit + push**

## New Workflow

```
1. /wrapup    → Document status, commit
2. /clear     → Clear context
3. /catchup   → Reload context
```

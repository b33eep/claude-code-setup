# Record 036: Project Template Versioning

## Status

Done

---

## Problem

When `templates/project-CLAUDE.md` gains new sections (e.g., "Recent Decisions" in v23, "Future" table), existing project CLAUDE.md files remain structurally outdated. The `--update` flag updates the template stored in `~/.claude/templates/CLAUDE.template.md` but intentionally never touches the project file — it contains user content that must not be overwritten.

Users miss new workflow features that depend on specific sections being present. Currently, the only way to catch up is to manually compare against the template and add missing sections — as was done in commit d29a7c7.

If left unaddressed, users with older projects won't benefit from template improvements unless they discover the gap themselves.

## Options Considered

### Option A: Version check in `/catchup`
- **Approach:** Add a `<!-- project-template: N -->` marker to the first line of the template and project files. `/catchup` compares the two numbers — if equal, zero overhead; if different, read full template and offer to add missing sections. Claude does the structural merge.
- **Pros:** Automatic detection, no extra command, minimal overhead (one-line read), Claude can intelligently merge (insert empty sections at correct position, preserve user content)
- **Cons:** Slightly more `/catchup` instructions, requires marker in every project file

### Option B: Dedicated command `/upgrade-project`
- **Approach:** User explicitly runs a command to check/update project CLAUDE.md against the template.
- **Pros:** User has full control, no overhead during normal `/catchup`
- **Cons:** Another command to discover and remember, users may never run it

### Option C: Integrate into `/claude-code-setup`
- **Approach:** Add project CLAUDE.md health check to the existing management command's status output.
- **Pros:** Natural place for "manage your installation"
- **Cons:** `/claude-code-setup` is global-scoped, project CLAUDE.md is per-project; mixes concerns

### Decision

Option A — version marker in first line with `/catchup` integration. Fast version comparison (first line only) avoids overhead on every session. Full template comparison only triggers when versions differ. First line placement is more robust than end-of-file (less likely to be accidentally deleted by users editing the bottom of the file).

Versioning approach: Use the existing content version (`templates/VERSION`) as the marker value rather than introducing a second version number. The marker records the content version at which the project CLAUDE.md was last synced against the template. After a content-only upgrade (no template change), `/catchup` reads the template once, finds no structural diff, and updates the marker. Small comment-line diff in project CLAUDE.md is acceptable — `/wrapup` modifies and commits the file regularly anyway.

## Solution

### Marker Format

First line of `templates/project-CLAUDE.md` and every project CLAUDE.md:

```
<!-- project-template: 25 -->
```

The number is the content version at which the project was last synced against the template structure.

### Affected Files

| File | Change |
|------|--------|
| `templates/project-CLAUDE.md` | Add marker as first line |
| `commands/catchup.md` | Add template version check step (early, before other work) |

`/init-project` copies the template as-is — marker comes along automatically. No other changes needed.

### `/catchup` Logic

New step added early in the catchup flow (before reading changed files):

1. Read first line of project CLAUDE.md → extract version number (or `0` if no marker)
2. Read first line of `~/.claude/templates/CLAUDE.template.md` → extract version number
3. If equal → skip, zero overhead
4. If different → read full template, compare section headers (`##` and `###` level) against project CLAUDE.md
5. If missing sections found → ask user: "Your project CLAUDE.md is missing sections: [list]. Add them?"
6. If user accepts → insert missing sections with empty template structure at correct position
7. Always update marker to current version (regardless of accept/decline/no missing sections)

### `/wrapup` Integration

No changes needed. `/wrapup` already commits project CLAUDE.md changes. The marker update naturally gets included in the next `/wrapup` commit.

### Edge Cases

| Case | Behavior |
|------|----------|
| No marker in project CLAUDE.md | Treated as version `0`, full comparison triggered |
| User declines update | Marker updated anyway — user won't be asked again until next template change |
| Multiple upgrades skipped (v23 → v28) | One template read catches all structural changes |
| Template hasn't changed since install | One-time read after upgrade, marker updated, no further checks |
| Project has extra sections not in template | Ignored — only missing sections are flagged |

## User Stories

### Story 1: Project Template Version Check

**As a** user with an existing project
**I want** `/catchup` to detect when my project CLAUDE.md is structurally outdated
**So that** I get new template sections without manually comparing files

**Acceptance Criteria:**
- [x] `templates/project-CLAUDE.md` has `<!-- project-template: N -->` as first line (N = current content version)
- [x] `commands/catchup.md` includes template version check step early in the flow
- [x] When versions match: no overhead, check is skipped
- [x] When versions differ: template is read, section headers compared
- [x] Missing sections are listed and user is asked before changes
- [x] On accept: missing sections inserted at correct position, marker updated
- [x] On decline: marker updated (won't be asked again until next template change)
- [x] Projects without marker are treated as version `0`
- [x] Content version bump includes marker in template

**Priority:** Medium

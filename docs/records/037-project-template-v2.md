# Record 037: Project Template v2

## Status

Done

---

## Problem

Three issues with the current project CLAUDE.md template and its lifecycle:

### 1. Records table is redundant

The Records table in project CLAUDE.md currently duplicates what's on disk in `docs/records/`. It requires manual sync (via `/wrapup` step 3) and grows unbounded — this project already has 36 entries eating ~40 lines of context. Claude can scan `docs/records/` directly with `ls` or `grep` at any time.

### 2. Template migration is fragile

Record 036 introduced version markers and section comparison in `/catchup`. But the migration logic lives as prose instructions in `catchup.md`, which Claude interprets differently each time. In the current session, Claude skipped the marker update entirely by reasoning "this is the project's own repo." The instructions need to be more explicit and isolated — a dedicated migration skill that `/catchup` triggers.

### 3. No project-specific User Instructions

Global CLAUDE.md has `<!-- USER INSTRUCTIONS START/END -->` markers that survive upgrades. Project CLAUDE.md has no equivalent. Users have no designated place for project-specific preferences that should survive `/wrapup` edits and template migrations (e.g., "always use pytest-asyncio", "deploy to staging before PR").

---

## Options Considered

### Change 1: Remove Records table

**Option A: Remove entirely, scan on demand**
- Remove `## Records` table from template and project CLAUDE.md
- `/catchup` and `/wrapup` scan `docs/records/` when needed
- Records are referenced by number in Status/Future tables (e.g., "[Record 022]")
- Pros: Less context consumed, no sync problem, single source of truth
- Cons: Claude needs to scan dir each time (fast, but an extra step)

**Option B: Keep table but auto-generate**
- Table stays but is rebuilt by `/wrapup` from disk
- Pros: Quick reference without scanning
- Cons: Still eats context, still a sync problem if `/wrapup` is skipped

**Decision: Option A** — Remove the table. Records on disk are the source of truth. Claude can `ls docs/records/` in one command. References from Status/Future tables provide direct links when needed. Saves ~40 lines of context that grow with every decision.

### Change 2: Migration skill instead of catchup prose

**Option A: Dedicated migration skill loaded by `/catchup`**
- Create a skill (e.g., `migrate-project-template`) with explicit step-by-step logic
- `/catchup` detects version mismatch → loads the skill → skill handles migration
- Skill compares sections, proposes changes, asks user, updates marker
- Pros: Isolated, testable logic; less interpretation variance; reusable
- Cons: One more skill file

**Option B: Improve catchup prose**
- Make the instructions in `catchup.md` more explicit and less ambiguous
- Pros: No new files
- Cons: Still depends on Claude interpretation, which already failed

**Decision: Option A** — Migration skill. The catchup prose approach has proven unreliable. A skill with explicit instructions reduces interpretation variance. `/catchup` step becomes: "if version mismatch → read and follow `~/.claude/skills/migrate-project-template/SKILL.md`."

### Change 3: Project User Instructions

**Option A: Section markers (same as global CLAUDE.md)**
- Add `<!-- PROJECT INSTRUCTIONS START/END -->` markers to project template
- `/wrapup` preserves content between markers (same as `build_claude_md` preserves global)
- Migration skill preserves this section
- Pros: Proven pattern, consistent with global CLAUDE.md
- Cons: None significant

**Option B: Separate file (e.g., `PROJECT_INSTRUCTIONS.md`)**
- Pros: Can't be accidentally overwritten
- Cons: One more file, less discoverable, not in CLAUDE.md context

**Decision: Option A** — Section markers in project CLAUDE.md. Consistent pattern with global CLAUDE.md. Users already know the convention.

---

## Solution

### Template Changes (`templates/project-CLAUDE.md`)

New template structure:

```markdown
<!-- project-template: N -->
# {Project Name}

## About
{1-2 sentences description}

## Tech Stack
{Language, framework, key dependencies}

---

## Current Status

| Story | Status | Notes |
|-------|--------|-------|
| US-1 | {Status} | {Brief info or [Record NNN](docs/records/NNN-slug.md)} |

**Legend:** Open | In Progress | Done

**Next Step:** {What's next}

### Future

| Todo | Priority | Problem | Solution |
|------|----------|---------|----------|

---

## Recent Decisions

| Date | Decision | Why |
|------|----------|-----|

---

## Project Instructions

<!-- PROJECT INSTRUCTIONS START -->
Add project-specific instructions, preferences, and conventions here.
This section is preserved during template migrations and /wrapup.

Examples:
- Testing preferences
- Deployment conventions
- Project-specific coding rules
- Hard constraints (e.g., "never break the public API")
- Areas to avoid (deprecated modules, frozen interfaces)
<!-- PROJECT INSTRUCTIONS END -->

---

## Architecture

{High-level architecture: key patterns, how components interact, data flow}

---

## Files

{Project file tree - key directories and files}

---

## Development

{Build, test, run commands}
```

**Removed:** `## Records` table (was between Current Status and Recent Decisions)

**Added:** `## Project Instructions` with markers (after Recent Decisions), `## Architecture` for high-level patterns and component interactions. `## Files` already existed and was kept as-is with added key directories hint.

**Moved:** `### Future` re-parented from under `## Records` to under `## Current Status` (matches current practice in this project). This is a structural move, not just a section removal — the migration command must handle this explicitly (see Migration Command below).

### Architecture Section (added in v48)

Research against official Anthropic guidance, community patterns (Shrivu Shankar enterprise usage, Boris/creator recommendations), and real-world usage confirmed Architecture as the #3 most recommended CLAUDE.md section (after Commands and Code Style).

**Why added:** High-level architecture context (key patterns, component interactions, data flow) helps Claude understand the system without reading every file. This is project knowledge that doesn't change every session but matters for every task.

**Why Code Style was NOT added:** Code style is handled by auto-loading coding standards skills (per Tech Stack). Adding it to the template would duplicate what skills already provide.

**`/wrapup` maintenance:** Added a new step to `/wrapup` that checks whether Development, Files, or Architecture sections need updates based on the session's work. This keeps these sections fresh without manual effort. Only updates when actual changes happened — no cosmetic rewrites.

Key research insights that informed this decision:
- Official Anthropic docs warn against bloated CLAUDE.md: "For each line, ask: Would removing this cause Claude to make mistakes?"
- Community consensus: essential sections are About, Tech Stack, Commands, Code Style, Architecture
- Our workflow sections (Status, Future, Decisions) are non-standard but are our differentiator for session continuity
- `/wrapup` as automated maintainer addresses the "stale information" anti-pattern

### Migration Skill

New file: `commands/migrate-project-template.md`

This is a command (not a context skill) that `/catchup` triggers when it detects a version mismatch. It's a command rather than a skill because it's invoked explicitly, not auto-loaded.

**Logic:**

1. Before making any changes, create backup: `CLAUDE.md.bak` (safety net for solo-mode users without Git)
2. Read current project CLAUDE.md fully
3. Read template from `~/.claude/templates/CLAUDE.template.md` (the **installed** template, not the repo source)
4. Compare sections by heading text (flat match, ignore nesting):
   - **Missing:** in template but not in project → ask user: "Add [section]?"
   - **Extra:** in project but not in template → ask user: "Still needed?" → if yes, leave as-is
   - **Present in both:** no action needed
5. **Special case — `### Future` re-parenting:** If `## Records` is being removed and `### Future` was its child, extract `### Future` content and re-insert under `## Current Status`
6. Present all proposed changes to user at once
7. Apply accepted changes:
   - Missing sections are inserted after the nearest preceding section that exists in both template and project. Existing section order is never changed.
   - Remove sections user confirmed to remove
   - Preserve all user content in existing sections
   - Preserve content between `<!-- PROJECT INSTRUCTIONS START/END -->` markers
8. Always update `<!-- project-template: N -->` marker to current version
9. Remove `CLAUDE.md.bak` after successful migration

### `/catchup` Changes

Replace current step 1 ("Check project template version") with:

```
1. **Check project template version**
   - Read first line of project CLAUDE.md → extract version from `<!-- project-template: N -->`
   - If no marker found: treat as version `0`
   - Use the Read tool on `~/.claude/templates/CLAUDE.template.md` (expand `~` to absolute path) → extract version from first line
   - If file does not exist (Read returns error) → skip this step
   - If versions match → skip, continue to next task
   - If versions differ → read and follow `commands/migrate-project-template.md` (the migration command)
   - After migration completes → continue with step 2 (Read project README.md)
```

### `/wrapup` Changes

- Step 2 ("Create Record"): Change "Add link to CLAUDE.md Records table" → "Reference in Current Status or Future table if actively relevant"
- Step 3 ("Sync Records table") → **Remove entirely**. No more Records table to sync.
- Add new rule: "When updating CLAUDE.md, do not add, remove, or change any content between the `<!-- PROJECT INSTRUCTIONS START -->` and `<!-- PROJECT INSTRUCTIONS END -->` markers. Treat this section as read-only during /wrapup."

### Global CLAUDE.md Changes

Update the "Keeping Records in sync" section:
- Remove: "`/wrapup` scans `docs/records/` and adds missing entries to the Records table"
- Replace: "Records live in `docs/records/`. Use `ls docs/records/` to list them. Reference specific Records by number in Status and Future tables."

Update the "After User Corrections" routing to include Project Instructions:
- Personal preferences → User Instructions (global CLAUDE.md)
- Project-specific preferences → Project Instructions (project CLAUDE.md)
- Project facts and constraints → Recent Decisions
- Session-specific context → Private Note

**Naming distinction:** Global uses "User Instructions" (personal, cross-project). Project uses "Project Instructions" (project-specific, shared with team). Different names to avoid confusion about scope.

---

## Affected Files

| File | Change |
|------|--------|
| `templates/project-CLAUDE.md` | Remove Records table, add Project Instructions, Files, and Architecture sections, re-parent Future |
| `commands/catchup.md` | Simplify step 1 to delegate to migration command |
| `commands/migrate-project-template.md` | **New** — migration command with explicit logic |
| `commands/wrapup.md` | Remove Records sync step, add Project Instructions preservation rule, add Development/Files/Architecture maintenance step |
| `commands/design.md` | Update line 468 "Syncs Record status with CLAUDE.md" — no more Records table |
| `templates/base/global-CLAUDE.md` | Update Records docs, After User Corrections routing |
| `templates/VERSION` | Bump version |
| `tests/scenarios/15-template-content.sh` | Replace Records assertions with Project Instructions/Files/Architecture assertions |
| `CLAUDE.md` | Migrate this project's own file (remove Records table, add Project Instructions) |
| `README.md` | Update version badge |
| `CHANGELOG.md` | Add entry |
| `website/pages/` | Update documentation site to reflect all changes (same PR) |
| `docs/records/036-project-template-versioning.md` | Update status: superseded by 037 |

---

## Migration Path

For existing users (project CLAUDE.md has Records table, no Project Instructions):

1. User runs `/catchup` → version mismatch detected
2. Migration command loads → identifies:
   - **Missing:** `## Project Instructions`, `## Architecture`, `## Files` → "Add?"
   - **Extra:** `## Records` table → "Still needed? (Records on disk in `docs/records/` are the source of truth.)"
   - **Extra:** `## Repository` → "Still needed?"
3. User decides per change
4. Marker updated regardless

For new users: `/init-project` copies template as-is — new structure from day one.

---

## Resolved Questions

1. **commands/ vs skills/?** → `commands/` — explicitly triggered by `/catchup`, not contextual auto-loading.
2. **Lightweight Records summary?** → No. Full removal. `ls docs/records/` is deterministic and fast.
3. **Section comparison algorithm?** → Flat heading-text match, ignore nesting. No reordering of existing sections. Special case for `### Future` re-parenting.
4. **Backup before migration?** → Yes. `CLAUDE.md.bak` created before changes, removed after success. Safety net for solo-mode without Git.
5. **"User Instructions" vs "Project Instructions" naming?** → Intentionally different. "User" = personal/global, "Project" = project-specific/team-shared.

# Migrate Project Template

Triggered by `/catchup` when it detects a version mismatch between the project CLAUDE.md and the installed template.

**Do NOT run this command directly.** It is invoked automatically by `/catchup`.

## Prerequisites

- Project CLAUDE.md exists in the current working directory
- Template exists at `~/.claude/templates/CLAUDE.template.md` (expand `~` to absolute path)
- Version mismatch detected (or no version marker in project CLAUDE.md)

## Steps

### 1. Create backup

Copy `CLAUDE.md` to `CLAUDE.md.bak` in the project root. This is a safety net for solo-mode users without Git.

### 2. Read both files

- Read full project CLAUDE.md
- Read full template from `~/.claude/templates/CLAUDE.template.md` (expand `~` to absolute path)
- Extract template version from first line: `<!-- project-template: N -->`

### 3. Compare sections

Compare `##` level headings by text (flat match, ignore nesting/position):

- **Missing:** heading exists in template but NOT in project → candidate to add
- **Extra:** heading exists in project but NOT in template → candidate to ask about
- **Present in both:** no action needed

Also compare `###` level headings the same way.

### 4. Special case: `### Future` re-parenting

If `## Records` exists in the project and is being removed, check if `### Future` is a child of `## Records`:
1. Extract `### Future` and all its content (table, entries)
2. After removing `## Records`, re-insert `### Future` under `## Current Status` (after the "Next Step" line)

### 5. Present changes to user

Show all proposed changes at once. For each change, ask the user:

**For missing sections:**
```
Template v{N} has new sections for your project CLAUDE.md:

- [ ] Add "## Project Instructions" (with preservation markers)
- [ ] Add "## Files" (project structure overview)

Add these sections?
```

**For extra sections:**
```
These sections are no longer in the template:

- [ ] "## Records" — Records on disk in docs/records/ are the source of truth. Remove table from CLAUDE.md?
- [ ] "## Repository" — Still needed?

Remove marked sections?
```

### 6. Apply accepted changes

**Insertion order:** Missing sections are inserted after the nearest preceding section that exists in both template and project. Existing section order is never changed.

**Removal:** Remove only sections the user confirmed. Preserve all user content in sections that stay.

**Preservation:** Never modify content between `<!-- PROJECT INSTRUCTIONS START -->` and `<!-- PROJECT INSTRUCTIONS END -->` markers.

### 7. Update version marker

**Always** update (or insert) `<!-- project-template: N -->` as the first line of project CLAUDE.md, where N is the template version. This happens regardless of whether the user accepted or declined any changes.

### 8. Cleanup

Remove `CLAUDE.md.bak` after successful migration.

## Edge Cases

| Case | Behavior |
|------|----------|
| No marker in project CLAUDE.md | Insert marker as first line |
| User declines all changes | Only marker is updated |
| `### Future` already under `## Current Status` | No re-parenting needed |
| `## Records` doesn't exist | Skip re-parenting logic |
| Project has custom sections not in template | Ask "Still needed?" — if yes, leave as-is |
| `<!-- PROJECT INSTRUCTIONS -->` markers already exist | Preserve content between them |

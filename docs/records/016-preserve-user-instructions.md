# Record 016: Preserve User Instructions in Global CLAUDE.md

## Status

Accepted

## Context

The global `~/.claude/CLAUDE.md` is managed by claude-code-setup. When users run `./install.sh --update` or `/claude-code-setup`, the file gets overwritten with the latest template version.

**Problem:** Users may add their own instructions to the global CLAUDE.md (personal preferences, project-wide conventions, API keys location hints, etc.). These customizations are lost on update.

## Options Considered

### Option 1: Separate Files

Keep managed content in `CLAUDE.md` and user content in `CLAUDE.user.md`.

**Pros:**
- Clean separation
- No risk of accidental overwrite

**Cons:**
- Claude Code only loads `CLAUDE.md` by default
- User must remember to use both files
- Unclear which file takes precedence

### Option 2: Section Markers (Recommended)

Use HTML comment markers to define a user-editable section:

```markdown
<!-- USER INSTRUCTIONS START -->
Your custom instructions here...
<!-- USER INSTRUCTIONS END -->
```

During update:
1. Extract content between markers from existing file
2. Apply new template
3. Re-insert preserved user content at marker location

**Pros:**
- Single file, simple mental model
- Explicit and visible markers
- User content preserved automatically
- Easy to implement

**Cons:**
- Markers must not be accidentally deleted by user
- Slightly more complex update logic

### Option 3: Append-Only Updates

Never overwrite existing content, only append new sections.

**Pros:**
- No risk of data loss

**Cons:**
- File grows with duplicates
- User must manually clean up
- Messy and confusing

### Option 4: Git-Style Merge

Attempt 3-way merge between old template, new template, and user's version.

**Pros:**
- Preserves all user changes anywhere in file

**Cons:**
- Complex to implement
- Merge conflicts possible
- Overkill for this use case

## Decision

**Option 2: Section Markers**

## Implementation

### 1. Template Change

Add section to `templates/base/global-CLAUDE.md`:

```markdown
---

## User Instructions

<!-- USER INSTRUCTIONS START -->
Add your personal instructions, preferences, and conventions here.
This section is preserved when updating claude-code-setup.
<!-- USER INSTRUCTIONS END -->
```

### 2. Update Logic in `lib/content.sh`

```bash
update_claude_md() {
    local target="$CLAUDE_DIR/CLAUDE.md"
    local template="$SCRIPT_DIR/templates/base/global-CLAUDE.md"

    # Extract user section if exists
    local user_content=""
    if [[ -f "$target" ]]; then
        user_content=$(sed -n '/<!-- USER INSTRUCTIONS START -->/,/<!-- USER INSTRUCTIONS END -->/p' "$target")
    fi

    # Copy new template
    cp "$template" "$target"

    # Re-insert user content if we had any
    if [[ -n "$user_content" ]]; then
        # Replace placeholder section with preserved content
        # (implementation details TBD)
    fi
}
```

### 3. First-Time Setup

On fresh install, the section contains helpful placeholder text:

```markdown
<!-- USER INSTRUCTIONS START -->
Add your personal instructions, preferences, and conventions here.
This section is preserved when updating claude-code-setup.

Examples:
- Preferred coding style
- Project naming conventions
- Locations of credentials/secrets
- Team-specific workflows
<!-- USER INSTRUCTIONS END -->
```

## Migration

Existing users (no markers):
- On update, add the section at the end
- Notify user: "Added User Instructions section - move your custom content there"

## Decisions

1. **Single user section at the bottom** - Our managed content first, user extends below
2. **Markers deleted = overwrite** - If user accidentally deletes markers, content gets overwritten. User's responsibility to keep markers intact.
3. **Not needed for project CLAUDE.md** - Project files are initialized once via /init-project, then fully owned by user

## References

- [Record 004: Document and Clear Workflow](004-document-and-clear-workflow.md)
- [Record 008: Content Versioning](008-content-versioning.md)

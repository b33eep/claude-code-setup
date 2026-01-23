# ADR-008: Content Versioning

**Status:** Accepted
**Date:** 2025-01-23

## Context

When users run `./install.sh --update`, managed content (global prompt, commands, skills, MCP configs) gets overwritten. Users have no way to know:

1. Whether content has changed since their last install
2. What specifically changed
3. Which version they currently have

The existing `CURRENT_VERSION` mechanism was designed for schema migrations (v1 → v2 for ADR-007), not for tracking content changes. Since the repo is fresh with no external v1 users, this migration code is unnecessary.

## Decision

### Content Version

- Single incrementing number (`1, 2, 3...`) in `templates/VERSION`
- Tracks all managed content: global prompt, commands, skills, MCP configs
- Stored in `.installed.json` as `"content_version": X`

### Changelog Integration

- Use existing `CHANGELOG.md` with "Content vX:" prefix
- No separate content changelog
- Before v1.0.0: All entries under `[Unreleased]`
- After v1.0.0: Entries move to release sections

### Format

```markdown
# Changelog

## [Unreleased]
- Content v3: Added /todo command
- Content v2: Security warning in global prompt
- Content v1: Initial content structure

## [1.0.0] - 2025-xx-xx
- Initial release
```

### Update Behavior

```
$ ./install.sh --update

Installed content: v2 → Available: v5
See CHANGELOG.md for details.
Proceed? (y/N)
```

### Migration Code Removal

Remove legacy schema migration (~120 lines):
- `CURRENT_VERSION=2`
- `run_migrations()`
- `prompt_migration_v1_to_v2()`
- `execute_migration_v1_to_v2()`
- `show_migration_v1_to_v2_instructions()`
- `get_version()` / `set_version()`

## Alternatives

| Alternative | Pros | Cons |
|-------------|------|------|
| Per-component versions | Granular tracking | 5 versions to maintain, complex |
| Git-hash based | Automatic, no manual versioning | Opaque, no semantic meaning |
| No versioning | Simplest | User has no visibility into changes |
| Separate content changelog | Dedicated, detailed | Double maintenance with CHANGELOG.md |

## Consequences

### Positive
- Users know when content has changed
- Single source of truth (CHANGELOG.md)
- Simpler codebase (~120 lines removed)
- Clear versioning model: content version (incrementing) + release version (SemVer)

### Negative
- Manual version bump required for content changes
- Content version and release version are separate concepts to understand

## Implementation

### Files to Create

**`templates/VERSION`**
```
1
```
Plain number, no prefix. Simple parsing with `cat`.

### Files to Modify

**`install.sh`**

Remove (~120 lines):
- `CURRENT_VERSION=2` (line 18)
- `get_version()` / `set_version()` (lines 83-91)
- `run_migrations()` (lines 569-593)
- `prompt_migration_v1_to_v2()` (lines 595-626)
- `execute_migration_v1_to_v2()` (lines 628-673)
- `show_migration_v1_to_v2_instructions()` (lines 675-688)
- Migration call in `do_update()` (line 704)
- Version reset in fresh install (line 790)

Add:
- `CONTENT_VERSION_FILE="$SCRIPT_DIR/templates/VERSION"`
- `get_content_version()` - read from templates/VERSION
- `get_installed_content_version()` - read from .installed.json
- `set_installed_content_version()` - write to .installed.json

Update `do_update()`:
```bash
installed_v=$(get_installed_content_version)
available_v=$(get_content_version)

if [ "$installed_v" -eq "$available_v" ]; then
    echo "Content version: v$available_v (up to date)"
    echo "Nothing to update."
    exit 0
fi

echo "Content version: v$installed_v → v$available_v"
echo "See CHANGELOG.md for details."
read -rp "Proceed? (y/N): " confirm
# ... continue with update
```

Update fresh install:
- Set `content_version` in .installed.json

**`.installed.json` Schema**
```json
{
  "content_version": 1,
  "mcp": [],
  "skills": []
}
```
Note: `version` and `standards` fields removed (legacy from schema migrations).

**`CHANGELOG.md`**
```markdown
## [Unreleased]
- Content v1: Initial managed content (global prompt, commands, skills, MCP)
```

### Version Bump Process

When changing any of these, increment `templates/VERSION`:
- `templates/base/global-CLAUDE.md`
- `commands/*.md`
- `skills/*/`
- `mcp/*.json`

Add corresponding entry to CHANGELOG.md:
```markdown
- Content vX: Description of change
```

### Behavior Summary

| Command | Version Match | Action |
|---------|---------------|--------|
| `--update` | Same | "Up to date. Nothing to update." Exit. |
| `--update` | Different | Show diff, ask confirm, update |
| (fresh) | N/A | Install all, set content_version |

## References

- [ADR-007: Coding Standards as Skills](007-coding-standards-as-skills.md) - Previous migration this replaces

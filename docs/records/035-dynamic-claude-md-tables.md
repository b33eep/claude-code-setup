# Record 035: Dynamic CLAUDE.md Table Generation

## Status

Done

---

## Problem

`build_claude_md()` copies a static template that hardcodes all module references in three tables (MCP Servers, Skills, Skill Loading). There is no mechanism to dynamically generate these tables based on `installed.json`.

### Consequences

1. **After Remove:** Claude still sees removed modules as available — attempts to use non-existent MCP tools, references deleted skills
2. **Custom Modules:** Never appear in CLAUDE.md tables — Claude doesn't know they exist
3. **After Install:** New built-in modules only appear after template update (content version bump)

### Root Cause

- `build_claude_md()` in `lib/skills.sh` does `cp "$template" "$target"` — static copy
- `do_remove()` in `lib/uninstall.sh` never calls `build_claude_md`
- No function reads `installed.json` to determine what should be in the tables
- Custom modules have no metadata in the template at all

## Options Considered

No alternative approaches — the existing codebase already uses marker-based section replacement for User Instructions (`<!-- USER INSTRUCTIONS START/END -->`). Extending this pattern to the three module tables is the natural continuation.

## Solution

Extend the existing marker pattern to dynamically generate MCP Servers, Skills, and Skill Loading tables based on `installed.json` + module metadata.

### 1. Template Changes

Add markers around the three tables in `templates/base/global-CLAUDE.md`:

```markdown
<!-- MCP_TABLE START -->
| Server | Description |
|--------|-------------|
| `pdf-reader` | Read and analyze PDF documents |
...
<!-- MCP_TABLE END -->

<!-- SKILLS_TABLE START -->
| Skill | Type | Description |
|-------|------|-------------|
| `standards-python` | context | Python coding standards |
...
<!-- SKILLS_TABLE END -->

<!-- SKILL_LOADING_TABLE START -->
| File Extension | Skill to Load |
|----------------|---------------|
| `.py` | `~/.claude/skills/standards-python/SKILL.md` |
...
<!-- SKILL_LOADING_TABLE END -->
```

Default content between markers serves as fallback for manual template usage.

### 2. Generic Marker Replacement Function

Reusable function (same awk pattern as User Instructions):

```bash
replace_marker_section() {
    local file="$1" marker_name="$2" content="$3"
    local start="<!-- ${marker_name} START -->"
    local end="<!-- ${marker_name} END -->"
    # awk: extract before start marker, append new content, extract after end marker
}
```

Refactor existing User Instructions replacement to also use this function (single code path).

### 3. Table Generation Functions

**MCP Table** — metadata from `mcp/{name}.json`:
```bash
generate_mcp_table() {
    # Read installed.json → mcp array
    # For each: jq .description from mcp/{name}.json or custom/mcp/{name}.json
    # Output: | `{name}` | {description} |
    # Empty: "> No MCP servers installed."
}
```

**Skills Table** — metadata from SKILL.md frontmatter:
```bash
generate_skills_table() {
    # Read installed.json → skills array
    # For each: sed extract description/type from SKILL.md or custom SKILL.md
    # Output: | `{name}` | {type} | {description} |
    # Empty: "> No skills installed."
}
```

**Skill Loading Table** — from `file_extensions` frontmatter field:
```bash
generate_skill_loading_table() {
    # Read installed.json → skills array (context type only)
    # For each: read file_extensions from SKILL.md frontmatter
    # Fallback: hardcoded lookup for legacy skills without field
    # Output: | {extensions} | `~/.claude/skills/{name}/SKILL.md` |
    # Empty: "> No context skills installed."
}
```

### 4. file_extensions Field in SKILL.md Frontmatter

**New field** added to all context skills that have file extension mappings:

```yaml
---
name: standards-python
description: Python coding standards...
type: context
applies_to: [python, fastapi, django]
file_extensions: [".py"]
---
```

```yaml
---
name: standards-typescript
description: TypeScript coding standards...
type: context
applies_to: [typescript, react, nextjs]
file_extensions: [".ts", ".tsx", ".jsx"]
---
```

**Benefits:**
- Zero code changes when adding new skills
- Custom skills can self-register in Skill Loading table
- Metadata lives with the skill, not in install logic

**Fallback:** Hardcoded `get_skill_extensions()` case statement for legacy skills without the field. Once all built-in skills have the field, fallback can be removed.

**SKILL.md frontmatter contract:** All values must be single-line, unquoted. Document this in skill-creator command.

### 5. Atomic Write for build_claude_md

To prevent data loss if marker replacement fails mid-execution:

1. Copy template to temp file
2. Run all marker replacements on temp file
3. Only `mv` temp file to target if all replacements succeed
4. On failure: leave original target untouched

### 6. Custom Module Handling

```
If name starts with "custom:" →
  Strip prefix, read from ~/.claude/custom/{mcp|skills}/
Else →
  Read from $SCRIPT_DIR/{mcp|skills}/
```

Custom skills appear in Skills table. Custom MCP appears in MCP table.
Custom skills with `file_extensions` in frontmatter appear in Skill Loading table.

### 7. Integration Points

- `build_claude_md()` in `lib/skills.sh`: Refactor to use `replace_marker_section` for all 4 sections (User Instructions + 3 tables)
- `do_remove()` in `lib/uninstall.sh`: Call `build_claude_md` at the end
- `do_install()` and `do_update()`: Already call `build_claude_md` — tables will be auto-generated

### 8. Coverage Matrix

| Module Type | MCP Table | Skills Table | Skill Loading | Remove Cleanup |
|---|---|---|---|---|
| Built-in MCP | Yes | — | — | Yes |
| Custom MCP | Yes | — | — | Yes |
| Built-in Skill (context) | — | Yes | Yes (frontmatter) | Yes |
| Built-in Skill (command) | — | Yes | No (not applicable) | Yes |
| Custom Skill (context) | — | Yes | Yes (if file_extensions set) | Yes |
| Custom Skill (command) | — | Yes | No (not applicable) | Yes |
| External Plugin | — | — | — | Not in these tables |

### 9. Edge Cases

| Situation | Behavior |
|---|---|
| installed.json missing or invalid JSON | Empty tables (header + hint text) |
| Metadata file missing | Skip entry, no error |
| No MCP installed | `> No MCP servers installed.` |
| No Skills installed | `> No skills installed.` |
| Custom skill without SKILL.md | Show name, empty description |
| Skill without file_extensions field | Fallback to hardcoded lookup, skip if unknown |
| build_claude_md fails mid-execution | Original CLAUDE.md untouched (atomic write) |

### 10. Known Limitations

**Web Search Preference section:** The static section under MCP Servers (lines 243-258) references `google-search` and `brave-search` by name. It uses conditional language ("When MCP search tools are installed") so it's harmless if neither is installed, but wastes ~16 lines of context. A future `MCP_SEARCH_PREFERENCE` marker section could conditionally include/exclude this, but is out of scope for this design.

## User Stories

### Story 1: Add file_extensions to SKILL.md frontmatter
**Priority:** High (prerequisite — data must exist before generation)

**Acceptance Criteria:**
- [ ] `file_extensions` field added to all standards-* skills
- [ ] skill-creator command updated to document the field
- [ ] Existing tests still pass

### Story 2: Add markers to template
**Priority:** High (prerequisite for dynamic generation)

**Acceptance Criteria:**
- [ ] `<!-- MCP_TABLE START/END -->` markers around MCP Servers table
- [ ] `<!-- SKILLS_TABLE START/END -->` markers around Skills table
- [ ] `<!-- SKILL_LOADING_TABLE START/END -->` markers around Skill Loading table
- [ ] Default content preserved between markers (fallback)
- [ ] Existing tests still pass

### Story 3: Implement replace_marker_section and table generation
**Priority:** High

**Acceptance Criteria:**
- [ ] Generic `replace_marker_section()` function
- [ ] Existing User Instructions refactored to use it (single code path)
- [ ] `generate_mcp_table()` reads installed MCP from installed.json + metadata
- [ ] `generate_skills_table()` reads installed skills from installed.json + SKILL.md frontmatter
- [ ] `generate_skill_loading_table()` reads file_extensions from frontmatter, fallback to hardcoded lookup
- [ ] Custom modules handled (custom: prefix → custom/ directory)
- [ ] Empty state handled (no modules → hint text)
- [ ] `build_claude_md()` uses atomic write pattern
- [ ] `build_claude_md()` calls all generators

### Story 4: Call build_claude_md after remove
**Priority:** High

**Acceptance Criteria:**
- [ ] `do_remove()` calls `build_claude_md` after removing modules
- [ ] Removed MCP no longer appears in CLAUDE.md MCP table
- [ ] Removed skill no longer appears in CLAUDE.md Skills + Skill Loading tables

### Story 5: Tests
**Priority:** High

**Acceptance Criteria:**
- [ ] Test: Install → module appears in CLAUDE.md tables
- [ ] Test: Remove → module disappears from CLAUDE.md tables
- [ ] Test: Custom skill with file_extensions → appears in Skill Loading table
- [ ] Existing scenario 15 updated for markers
- [ ] Existing scenario 16 extended to check CLAUDE.md cleanup

### Story 6: Documentation + version bump
**Priority:** Low

**Acceptance Criteria:**
- [ ] Content version bumped
- [ ] CHANGELOG entry
- [ ] README badge updated
- [ ] Record 035 status → Done

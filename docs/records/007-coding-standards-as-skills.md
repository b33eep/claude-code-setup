# Record 007: Coding Standards as Context Skills

**Status:** Accepted
**Date:** 2026-01-23

## Context

Coding standards in `global-CLAUDE.md` are static and don't adapt to project type. A Python project gets the same standards as a TypeScript project. The Code Review Checklist contains language-specific items (e.g., `frozen=True` for Python) that aren't relevant for all projects.

Problems:
- Standards don't match the project's tech stack
- Unnecessary cognitive load from irrelevant rules
- No way to customize standards per language

## Decision

Convert coding standards from static content in `global-CLAUDE.md` to **context skills** that are automatically loaded based on the project's tech stack.

### New Skill Type: `context`

```yaml
---
name: standards-python
description: This skill provides Python coding standards...
type: context           # Auto-loaded, not manually invoked
applies_to: [python, fastapi, django, flask, pytest]
---
```

| Type | Behavior |
|------|----------|
| `command` (default) | Explicitly invoked via `/skill-name` |
| `context` | Auto-loaded when `applies_to` matches tech stack |

### Matching Strategy

**Partial Match:** If any item from the project's tech stack appears in `applies_to`, the skill is loaded.

Example:
- Project: `Tech Stack: Python, FastAPI, PostgreSQL`
- Skill: `applies_to: [python, fastapi, django]`
- Result: Skill loads (both `python` and `fastapi` match)

### Customization Strategy

**Override:** Custom skills in `~/.claude/custom/skills/` take priority over installed skills.

- `~/.claude/skills/standards-python/` ← from claude-code-setup
- `~/.claude/custom/skills/standards-python/` ← user's version (wins)

Users who customize accept responsibility for merging upstream updates.

### Skill Structure

```
skills/
├── standards-python/
│   ├── SKILL.md
│   └── references/
│       └── code-review-checklist.md
│
├── standards-typescript/
│   ├── SKILL.md
│   └── references/
│       └── code-review-checklist.md
```

### Changes to Global CLAUDE.md

Remove:
- `## Coding Standards` section
- `## Code Review Checklist` section
- `{{STANDARDS_MODULES}}` placeholder

Keep:
- Workflow (Session Management, Development Flow)
- Git Commit Messages (language-agnostic)
- File Structure explanation

## Migration Strategy

Existing users have inline coding standards in `~/.claude/CLAUDE.md`. The migration must handle this gracefully.

### Detection

The installer detects old setup by checking for:
- `## Coding Standards` section in `~/.claude/CLAUDE.md`
- `## Code Review Checklist` section in `~/.claude/CLAUDE.md`

### Interactive Migration Prompt

```bash
./install.sh --update

⚠️  Coding Standards have moved to Skills (Record 007).

Your current setup has inline standards in ~/.claude/CLAUDE.md.
The new approach uses context-aware skills per language.

Options:
  [a] Automatic migration (backup created)
  [m] Manual migration (show instructions)
  [s] Skip for now (keep old setup)

Choice [a/m/s]:
```

### Option: Automatic Migration

1. Create backup: `~/.claude/CLAUDE.md.bak`
2. Remove `## Coding Standards` section from `~/.claude/CLAUDE.md`
3. Remove `## Code Review Checklist` section from `~/.claude/CLAUDE.md`
4. Install `skills/standards-python/` and `skills/standards-typescript/`
5. Show summary of changes

### Option: Manual Migration

Display instructions:
```
See migration guide: docs/migration/001-standards-to-skills.md

Steps:
1. Remove ## Coding Standards from ~/.claude/CLAUDE.md
2. Remove ## Code Review Checklist from ~/.claude/CLAUDE.md
3. Run: ./install.sh --add skills/standards-python
4. Add "Tech Stack: Python" to your project CLAUDE.md
```

### Option: Skip

```
Skipped. Your current setup continues to work.
Run './install.sh --update' again when ready to migrate.
```

Old inline standards remain functional. User can migrate later.

### Project CLAUDE.md

Existing projects without `Tech Stack:` field:
- Context skills won't auto-load (no match possible)
- User adds `Tech Stack:` manually or via next `/init-project` run
- Documented in migration guide

## Alternatives

| Alternative | Pros | Cons |
|-------------|------|------|
| Keep static standards | Simple, no changes | Doesn't adapt to project |
| Standards in Project CLAUDE.md | Project-specific | Duplication, no reuse |
| **Context skills** | Reusable, auto-loading, customizable | New concept to learn |

## Consequences

### Positive
- Standards match the project's tech stack automatically
- Cleaner `global-CLAUDE.md` (workflow only)
- Language-specific code review checklists
- Extensible (add Go, Rust, Java later)
- Customizable via `~/.claude/custom/`

### Negative
- New `type: context` concept in skill system
- Requires implementation in session start logic
- Users must understand matching behavior
- Existing users must migrate (interactive prompt helps)

## Scope

Initial implementation: Python, TypeScript
Future: Java, Go, Rust (when standards are defined)

## References

- [Record 001: Modular Architecture](001-modular-architecture.md)
- [Skill Creator by AJBcoding](https://github.com/AJBcoding/claude-skill-eval/tree/main/skills/skill-creator)

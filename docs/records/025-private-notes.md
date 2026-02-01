# Record 025: Private Notes

**Status:** Done
**Priority:** Medium
**Date:** 2026-02-01

## Problem

During sessions, notes are created that don't belong in the repo:
- Session logs
- Research results
- Promotion strategies
- Personal TODOs

Currently in `docs/notes/` - already gitignored.

## Solution

### Filename Marker Convention

Use `.open` suffix to mark notes that should be loaded:

```
docs/notes/
├── session-2026-02-01.open.md   ← /catchup loads this
├── session-2026-01-30.md        ← closed, ignored
└── research-topic.open.md       ← /catchup loads this
```

**Why filename marker:**
- Simple glob: `*.open.md`
- No content parsing needed
- Visible in file listing
- Easy to close: rename to remove `.open`

### /catchup Integration

Add to `/catchup` command:

```markdown
## Private Notes

Check for open notes in `docs/notes/`:
- Glob: `docs/notes/*.open.md`
- If found: Read and summarize
- Show: "Open notes found: [list]"
```

### Global Prompt Addition

Add to `~/.claude/CLAUDE.md`:

```markdown
### Private Notes

Project-specific private notes live in `docs/notes/` (gitignored).
- Use `.open.md` suffix for notes that should be loaded by /catchup
- Rename to `.md` when done to close them
```

## Design Decision: Loading Behavior

**Why different from Records?**

| Aspect | Records | Notes |
|--------|---------|-------|
| Loading | Selective (referenced in CLAUDE.md) | All open (glob `*.open.md`) |
| Quantity | Many (accumulate over time) | Few (temporary) |
| Lifespan | Permanent | Session-bound |
| Control | Explicit reference in status tables | Filename suffix |

Records need selective loading because projects accumulate many (25+). Loading all would waste context.

Notes use glob because the user controls what's "open" - the assumption is that notes are closed (renamed to `.md`) when no longer needed.

## Implementation

1. [x] Update global CLAUDE.md template
2. [x] Update /catchup command
3. [x] Rename current session note to `.open.md`
4. [x] Documentation site page

## Open Questions

- Global notes (`~/.claude/notes/`) needed? → Defer, start with project-only

## References

- Current notes: `docs/notes/session-*.md`
- [Record 018](018-todo-command.md) - /todo as inspiration

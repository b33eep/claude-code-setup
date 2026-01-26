# Record 003: Solo vs Team Mode

**Status:** Accepted
**Date:** 2026-01-23

## Context

Project `CLAUDE.md` files contain:
- Project overview (static, shareable)
- Current status and session notes (dynamic, personal)
- User stories and tasks (depends on workflow)

Two distinct use cases emerged:

1. **Solo developer**: CLAUDE.md contains personal session state, not useful for others
2. **Team**: CLAUDE.md serves as shared project context for all developers

## Decision

During `/init-project`, ask the user:

```
How will you use CLAUDE.md in this project?

1) Solo - Add to .gitignore (personal workflow, not shared)
2) Team - Track in Git (shared context for all developers)
```

- **Solo mode**: Add `CLAUDE.md` to `.gitignore`
- **Team mode**: Keep `CLAUDE.md` tracked in Git

The `/wrapup` command respects this choice:
- Solo: Only commits Records and code changes
- Team: Commits CLAUDE.md updates

## Alternatives

| Alternative | Pros | Cons |
|-------------|------|------|
| Always track | Simple, consistent | Personal notes in Git history |
| Always ignore | Private by default | Teams can't share context |
| **User choice** | Fits both use cases | Extra question during setup |
| Separate files | Clear separation | More files to manage |

## Consequences

### Positive
- Supports both solo and team workflows
- User makes explicit choice
- `/wrapup` adapts automatically

### Negative
- Extra step during project initialization
- Users might choose wrong option initially
- Team members must coordinate on choice

## References

- `/init-project` command
- `/wrapup` command

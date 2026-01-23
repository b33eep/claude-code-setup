# ADR-000: Core Workflow with Commands

**Status:** Accepted
**Date:** 2025-01-23

## Context

Claude Code has a context limit. When reached, users lose their working state. The challenge:

- How to preserve project knowledge across sessions?
- How to quickly resume after context clear?
- How to maintain consistent project state?

Claude Code offers built-in features like `/compact`, but these are lossy and unpredictable.

## Decision

Implement a three-command workflow with CLAUDE.md as persistent memory:

### The Commands

| Command | When | Purpose |
|---------|------|---------|
| `/init-project` | New project | Create CLAUDE.md with project structure |
| `/clear-session` | Before /clear | Document status, commit state |
| `/catchup` | After /clear | Read CLAUDE.md + changed files |

### The Flow

```
┌─────────────────────────────────────────────────────────┐
│  NEW PROJECT                                            │
│  → /init-project                                        │
│  → Creates CLAUDE.md, docs/adr/                         │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  DEVELOPMENT SESSION                                    │
│  → Work on tasks                                        │
│  → Update CLAUDE.md status                              │
│  → Create ADRs for decisions                            │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  CONTEXT LIMIT APPROACHING                              │
│  → /clear-session (document + commit)                   │
│  → /clear (reset context)                               │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  NEW SESSION                                            │
│  → CLAUDE.md auto-loads                                 │
│  → /catchup (read changed files)                        │
│  → Continue where you left off                          │
└─────────────────────────────────────────────────────────┘
```

### CLAUDE.md as Memory

The project CLAUDE.md contains:
- Project overview and tech stack
- Current status table (stories, progress)
- "What was done" in last session
- "Next Step" - clear action to resume
- Architecture decisions (links to ADRs)

## Alternatives

| Alternative | Pros | Cons |
|-------------|------|------|
| Use /compact | Built-in | Lossy, unpredictable |
| External tools (Serena, etc.) | Feature-rich | Complex setup, dependencies |
| No workflow | Simple | Lose context every session |
| **Command-based workflow** | Explicit, versioned, portable | Requires discipline |

## Consequences

### Positive
- CLAUDE.md is human-readable and Git-versioned
- Works across machines and sessions
- Clear handoff points (/clear-session → /clear → /catchup)
- Self-documenting project history
- No external dependencies

### Negative
- Requires user discipline to run commands
- CLAUDE.md needs curation to stay useful
- Manual process (not automatic)

## References

- "How I Use Every Claude Code Feature" - Inspiration
- `/init-project` command - [commands/init-project.md](../../commands/init-project.md)
- `/clear-session` command - [commands/clear-session.md](../../commands/clear-session.md)
- `/catchup` command - [commands/catchup.md](../../commands/catchup.md)

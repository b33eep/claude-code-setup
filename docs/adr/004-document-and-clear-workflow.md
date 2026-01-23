# ADR-004: Document & Clear Workflow

**Status:** Accepted
**Date:** 2026-01-23

## Context

Claude Code offers `/compact` to reduce context when approaching limits. However, auto-compaction has issues:

- Loss of important context during summarization
- Unpredictable behavior
- No persistent memory between sessions
- Error-prone in complex sessions

The question: How to handle context limits reliably?

## Decision

Adopt the "Document & Clear" workflow instead of `/compact`:

1. **Before context limit**: Run `/clear-session`
   - Update CLAUDE.md with current status
   - Document what was done
   - Set clear "Next Step"
   - Commit changes (if Team mode)

2. **Clear context**: Run `/clear`
   - Fresh start with full context budget

3. **Resume work**: Run `/catchup`
   - CLAUDE.md auto-loads with documented state
   - Read recent file changes
   - Continue where you left off

## Alternatives

| Alternative | Pros | Cons |
|-------------|------|------|
| Use /compact | Built-in, automatic | Lossy, unpredictable |
| **Document & Clear** | Explicit, reliable, versioned | Manual steps required |
| External memory tools | Sophisticated | Complex setup, dependencies |
| Just start fresh | Simple | Lose all context |

## Consequences

### Positive
- Explicit control over what's preserved
- CLAUDE.md serves as durable, versioned memory
- Works across sessions and even machines
- Human-readable state (not hidden in Claude's context)

### Negative
- Requires discipline to run `/clear-session`
- Manual process (not automatic)
- CLAUDE.md can get verbose if not curated

## References

- [How I Use Every Claude Code Feature](https://blog.anthropic.com/) - Philosophy source
- `/clear-session` command
- `/catchup` command

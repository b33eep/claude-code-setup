# Record 012: Optional Hooks for Workflow Automation

**Status:** Rejected
**Date:** 2025-01-24
**Revised:** 2025-01-27

## Context

The current workflow requires three manual steps when context gets full:

```
1. /clear-session  → Document status, commit
2. /clear          → Clear context
3. /catchup        → Reload context
```

Users often forget these steps, leading to:
- Auto-compact triggered without documentation
- Lost context
- Frustration

## Research Summary

We investigated several approaches to automate this workflow:

| Approach | Result |
|----------|--------|
| PreCompact Hook | ❌ Cannot prevent auto-compact, runs too late |
| Stop Hook + Context Monitoring | ⚠️ Can warn, but cannot invoke commands |
| SessionStart Hook | ⚠️ Can inject text, but cannot run /catchup |
| SlashCommand Tool | ❌ Not accessible to Claude (cannot run `/clear`) |
| SQLite + AI compression | ❌ Rejected (token costs, opaque, complexity) |

## Decision

**Rejected.** Hooks cannot invoke Claude commands.

### The Fundamental Problem

Hooks can only execute bash commands. They **cannot**:
- Run Claude slash commands (`/clear-session`, `/catchup`)
- Make Claude read files
- Make Claude load skills
- Make Claude do anything intelligent

| What we need | Hook can do it? |
|--------------|-----------------|
| `/clear-session`: Update CLAUDE.md with status | ❌ Requires Claude |
| `/clear-session`: Git commit | ✅ Yes |
| `/catchup`: List changed files | ✅ Yes |
| `/catchup`: Read and understand files | ❌ Requires Claude |
| `/catchup`: Load context skills | ❌ Requires Claude |

### What Hooks CAN Do

- Run bash commands (git, jq, etc.)
- Output text to Claude's context (SessionStart stdout)
- Output warnings to user (stderr)
- Auto-commit changes

### What Hooks CANNOT Do

- Invoke `/clear-session` to update CLAUDE.md intelligently
- Invoke `/catchup` to have Claude read files
- Make Claude perform any action

### Why This Makes the Feature Useless

The goal was: **User only types `/clear`, everything else is automated.**

But without the ability to invoke Claude commands:
- Stop hook can warn + auto-commit, but cannot update CLAUDE.md status
- SessionStart hook can inject file lists, but Claude won't read them

Injecting `echo "Run /catchup for full context reload if needed."` defeats the purpose entirely.

## Alternatives

1. **Wait for Claude Code feature** - Many GitHub issues request programmatic `/compact` or `/clear`
2. **Accept the limitation** - Keep the 3-step manual workflow
3. **Improve documentation** - Make the workflow easier to remember

## Related GitHub Issues

- [#7627](https://github.com/anthropics/claude-code/issues/7627) - User-invocable commands
- [#16988](https://github.com/anthropics/claude-code/issues/16988) - Hook-based compaction
- [#18027](https://github.com/anthropics/claude-code/issues/18027) - Context visibility
- [#19877](https://github.com/anthropics/claude-code/issues/19877) - Workflow-instruction-based compaction

All feature requests are open. Anthropic has not implemented command invocation from hooks.

## Conclusion

The hooks approach is not viable until Claude Code provides a way to invoke commands programmatically. The current 3-step workflow remains:

```
1. /clear-session  (manual)
2. /clear          (manual)
3. /catchup        (manual)
```

## References

- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)
- [Record 004: Document & Clear Workflow](004-document-and-clear-workflow.md)

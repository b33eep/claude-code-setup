# ADR-001: Modular Architecture

**Status:** Accepted
**Date:** 2025-01-23

## Context

The initial setup had a monolithic `global-CLAUDE.md` containing all coding standards (Python, TypeScript, Design Patterns) in one file. This caused several issues:

- Users had to include standards for languages they don't use
- Token consumption increased unnecessarily
- Adding new standards required editing a large file
- No clear extension point for community contributions

## Decision

Split the setup into composable modules:

```
templates/
├── base/global-CLAUDE.md     # Core: Workflow, conventions
└── modules/standards/
    ├── python.md             # Optional
    ├── typescript.md         # Optional
    └── design-patterns.md    # Optional
```

The installer builds `~/.claude/CLAUDE.md` from base + selected modules.

## Alternatives

| Alternative | Pros | Cons |
|-------------|------|------|
| Monolithic file | Simple, single file | Bloated, inflexible |
| Separate files loaded by Claude | No build step | Claude loads multiple files, unclear precedence |
| **Modular with build** | Flexible, extensible, single output | Requires installer logic |

## Consequences

### Positive
- Users install only what they need
- Smaller CLAUDE.md = fewer tokens
- Easy to add new modules (Go, Rust, etc.)
- Clear contribution path for community

### Negative
- More complex installer
- Users must re-run installer to add modules
- Module dependencies not yet supported

## References

- [Claude Code Documentation](https://docs.anthropic.com/claude-code)

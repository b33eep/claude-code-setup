# Record 002: Custom Modules Directory

**Status:** Accepted
**Date:** 2026-01-23

## Context

Teams and companies need to add their own:
- Coding standards (company style guides)
- MCP servers (internal tools)
- Skills (company-specific workflows)

Without a solution, users would fork the repository and diverge, making upstream updates difficult.

## Decision

Introduce `~/.claude/custom/` directory for user-owned modules:

```
~/.claude/custom/
├── standards/    # Custom coding standards
├── mcp/          # Custom MCP server configs
└── skills/       # Custom skills
```

The installer:
1. Creates this directory structure
2. Scans for custom modules during install
3. Includes them in selection wizard
4. Prefixes custom modules with `custom:` in tracking

## Alternatives

| Alternative | Pros | Cons |
|-------------|------|------|
| Fork repository | Full control | Diverges from upstream, hard to update |
| Environment variables | No extra files | Complex, limited |
| **Custom directory** | Clean separation, easy updates | Requires scanning logic |
| External config file | Explicit sources | Another file to manage |

## Consequences

### Positive
- Main repo stays clean and updateable (`git pull`)
- Teams can maintain separate module repos
- Clear separation: community vs. private
- Easy setup: `git clone company-repo ~/.claude/custom`

### Negative
- Custom modules not version-controlled with main repo
- Users must manage custom directory separately
- Potential naming conflicts (mitigated by `custom:` prefix)

## References

- Team workflow documented in README.md

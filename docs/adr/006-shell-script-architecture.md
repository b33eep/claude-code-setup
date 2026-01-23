# ADR-006: Shell Script Architecture

**Status:** Accepted
**Date:** 2025-01-23

## Context

The `install.sh` script has grown to ~800 lines. Questions arose about:
- Should we split it into multiple files?
- Should we rewrite in Python/Node?
- Should we distribute via Homebrew?

## Decision

**Keep as single-file Bash script.**

### Rationale

1. **Single file is shell best practice** - Splitting shell scripts complicates distribution and creates fragile path dependencies
2. **800 lines is acceptable** - Still readable, ShellCheck compliant, well-structured with function sections
3. **Zero runtime dependencies** - Only requires bash + jq (auto-installed via Homebrew)
4. **Matches user expectations** - `./install.sh` is the standard pattern for setup scripts
5. **Repo context matters** - Users clone the repo to see/modify templates, not just run an installer

### Why not Homebrew?

- Users need repo access for custom modules (`~/.claude/custom/`)
- Adds maintenance burden (Formula updates)
- Overkill for a setup script that runs once

### Why not Python/Node?

- Would add runtime dependency
- Current scope doesn't require advanced features (parsing, state management)
- Shell is idiomatic for file operations and CLI interaction

## Alternatives

| Alternative | Pros | Cons |
|-------------|------|------|
| Split into multiple .sh files | Smaller files | Distribution complexity, fragile paths |
| Python (click) | Testable, readable | Requires Python runtime |
| Node.js | Matches MCP ecosystem | Requires Node runtime |
| Homebrew distribution | Professional UX | Loses repo context, maintenance overhead |

## Consequences

### Positive
- Simple distribution (clone + run)
- No runtime dependencies beyond macOS defaults
- Easy for contributors to understand and modify

### Negative
- Unit testing is difficult
- Complex logic requires careful structuring
- Future growth limited to ~1000 lines

## Review Triggers

Consider revisiting this decision if:
- Script exceeds 1000 lines
- Complex parsing/state management needed
- Unit test coverage becomes critical
- Windows/Linux support required

## References

- [ShellCheck](https://www.shellcheck.net/) - Static analysis for shell scripts
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

# Record 018: /todo Command

## Status

Accepted

## Context

Manually editing CLAUDE.md to add todos is cumbersome. Users need to open the file, find the Future table, and format a new row correctly. This friction discourages keeping the todo list current.

Additionally, complex todos tend to bloat CLAUDE.md with details that belong in Records.

## Decision

Create a `/todo` command that:

1. **Lists todos** when called without arguments
2. **Adds todos** when called with a description
3. **Assesses complexity** to decide between inline entry vs Record:
   - Simple todos: row in Future table with inline Problem/Solution
   - Complex todos: create a Record, link from Future table

## Design Principles

- **CLAUDE.md stays lean**: Details belong in Records, not in the Future table
- **Low friction**: `/todo Fix bug` is faster than manual editing
- **Smart defaults**: Claude assesses priority and complexity, asks when unsure
- **Consistent format**: Matches existing Future table structure

## Future Table Format

```markdown
| Todo | Priority | Problem | Solution |
|------|----------|---------|----------|
| Simple task | Low | Brief problem | Brief solution |
| Complex feature | Medium | Brief problem | [Record NNN](docs/records/NNN-title.md) |
```

## Complexity Heuristics

| Simple | Complex |
|--------|---------|
| One-liner fix | Needs spec or design |
| Single file change | Multiple sessions expected |
| Config tweak | Architecture decision |
| Bug fix with clear cause | Would need >5 lines in CLAUDE.md |

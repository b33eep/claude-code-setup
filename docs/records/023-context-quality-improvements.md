# Record 023: Context Quality Improvements

**Status:** Planned
**Priority:** Medium
**Date:** 2026-01-30

## Problem

After `/clear`, important context can be lost:

1. **Small decisions fall through** - Not big enough for a Record, but important
2. **Session context lost** - What was discussed, why decisions were made
3. **Manual documentation burden** - /catchup relies on manually maintained status

## Solution

Three improvements to increase context quality:

### 1. Decision Log (lightweight)

Add a "Recent Decisions" section to project CLAUDE.md:

```markdown
## Recent Decisions

| Date | Decision | Why |
|------|----------|-----|
| 2026-01-30 | No version bump for security fix | Backwards compatible |
| 2026-01-29 | Use pip --user for yt-dlp | Avoids PEP 668 issues |
```

- Lighter than Records
- More persistent than chat
- /wrapup adds entries, /catchup reads them
- Auto-cleanup: Keep last 10-15 entries

### 2. Session Notes

Add "Last Session" summary to project CLAUDE.md:

```markdown
## Last Session (2026-01-30)

- Security review completed
- Trust model documented in SECURITY.md
- PR #22 merged
```

- /wrapup writes this (overwrites previous)
- /catchup reads it first
- Quick context without reading all Records

### 3. Auto-Context from Git

Enhance /catchup to extract context from git:

```bash
# Recent commits
git log --oneline -5

# Files changed recently
git diff --name-only HEAD~5
```

- Less manual documentation
- Always up-to-date
- Complements manual notes

## Implementation

### Phase 1: Decision Log
- [ ] Add section template to project CLAUDE.md
- [ ] Update /wrapup to prompt for decisions
- [ ] Update /catchup to read decisions

### Phase 2: Session Notes
- [ ] Add "Last Session" section
- [ ] /wrapup auto-generates summary
- [ ] /catchup reads it

### Phase 3: Auto-Context
- [ ] Enhance /catchup with git log extraction
- [ ] Smart filtering (ignore docs-only commits?)

## Trade-offs

| Pro | Con |
|-----|-----|
| Better context after /clear | More sections in CLAUDE.md |
| Less manual work (phase 3) | Git history can be noisy |
| Decisions don't get lost | Decision log needs pruning |

## References

- [Record 000](000-core-workflow.md) - Core workflow
- [Record 004](004-document-and-clear-workflow.md) - Document & Clear

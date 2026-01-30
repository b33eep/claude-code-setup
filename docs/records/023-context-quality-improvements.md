# Record 023: Context Quality Improvements

**Status:** Done
**Priority:** Medium
**Date:** 2026-01-30

## Problem

After `/clear`, small decisions with their reasoning are lost.

### What's NOT the problem

- **Manual documentation** - /wrapup already automates status updates
- **Session context** - "What was done" section captures actions

### The actual gap

| Layer | Persistence | Example |
|-------|-------------|---------|
| Records | Permanent | Architecture decisions, feature specs |
| ??? | ??? | "No version bump because backwards-compatible" |
| Chat | Lost after /clear | All discussion context |

**Small decisions fall through the gap.** They have a "why" worth remembering but are too small for a full Record.

### Real examples

- "No version bump for security fix" → Why? Backwards compatible, no API change
- "pip --user for yt-dlp" → Why? Avoids PEP 668 externally-managed error
- "Rejected auto-permissions" → Why? May discourage new users

These get lost after `/clear`, leading to:
- Repeated discussions
- Inconsistent decisions
- Lost institutional knowledge

## Solution: Decision Log

Add a "Recent Decisions" section to project CLAUDE.md:

```markdown
## Recent Decisions

| Date | Decision | Why |
|------|----------|-----|
| 2026-01-30 | No version bump for security fix | Backwards compatible, no API change |
| 2026-01-29 | pip --user for yt-dlp | Avoids PEP 668 externally-managed error |
```

### Design decisions

| Aspect | Decision | Rationale |
|--------|----------|-----------|
| **When to add** | Immediately when decision is made | Don't wait for /wrapup - context is fresh |
| **Max entries** | 20 | Enough history without bloat |
| **Pruning** | Claude decides based on relevance | Not FIFO - old decisions may still be relevant |
| **Placement** | After Records table | Records = permanent, Decisions = ephemeral |

### Pruning criteria (when >20 entries)

Remove decisions that:
- Are already documented in a Record
- Have been superseded by newer decisions
- Are too generic or obvious in hindsight

## Implementation

### Phase 1: Decision Log

1. **Update global CLAUDE.md** - Add workflow instruction:
   ```markdown
   ## Workflow: Decisions

   When making a decision that:
   - Has a "why" worth remembering
   - Is too small for a Record
   - Might come up again

   → Immediately add to "Recent Decisions" in project CLAUDE.md
   ```

2. **Update project template** - Add section after Records:
   ```markdown
   ## Recent Decisions

   | Date | Decision | Why |
   |------|----------|-----|
   ```

3. **Update /catchup** - Read Recent Decisions section

4. **Update /wrapup** - No change needed (decisions added in real-time)

### Future phases (optional)

- **Session Notes** - "Last Session" summary (may be redundant with "What was done")
- **Auto-Context from Git** - Already in /catchup, could be enhanced

## Trade-offs

| Pro | Con |
|-----|-----|
| Decisions survive /clear | One more section in CLAUDE.md |
| Immediate capture = no forgetting | Requires discipline to add |
| Claude prunes intelligently | Pruning is somewhat subjective |
| Lightweight (one line per decision) | Could grow noisy if overused |

## Resolved questions

1. **What qualifies as a "decision"?** Criteria documented in global template.
2. **Solo vs Team mode?** No special handling - CLAUDE.md is already gitignored in Solo mode.
3. **Overlap with Records?** Graduation criteria documented in global template.

## References

- [Record 000](000-core-workflow.md) - Core workflow
- [Record 004](004-document-and-clear-workflow.md) - Document & Clear

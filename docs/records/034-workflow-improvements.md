# Record 034: Workflow Improvements (Correction Trigger + Re-Plan Signs)

## Status

Designed

---

## Problem

Two gaps in the global prompt identified through comparison with community best practices:

### 1. No Correction Capture Trigger
When the user corrects Claude ("Never use sudo on this project", "This API expects ISO-8601"), this knowledge is lost after `/clear`. The persistence layers exist (Recent Decisions, Records, User Instructions, Private Notes) but there is no **trigger** telling Claude to recognize corrections as persistence-worthy events.

### 2. Vague Re-Plan Guidance
Claude Code's system prompt says "If your approach is blocked, don't brute force." But it lacks **concrete signals** for when to consider yourself blocked. In practice, Claude interprets obstacles as solvable problems and pushes through with workarounds instead of reassessing.

## Options Considered

### Dedicated Lessons File (Rejected)

A `docs/notes/lessons.open.md` for error patterns (inspired by `tasks/lessons.md` from community).

**Rejected because:** Architecturally identical to Private Notes. The storage exists; what's missing is the routing trigger.

### Full Behavioral Rules (Rejected)

Initially designed three verbose additions (~300 tokens): full Stop & Re-Plan rule, Capture Corrections with routing table, Verification Checkpoint.

After architect review:
- **Full Stop & Re-Plan (~140 tokens) — rejected.** Duplicates Claude Code's native instruction. The vague instruction isn't the problem; missing concrete triggers are.
- **Detailed routing table in Capture Corrections — rejected.** Too granular with examples. Slim routing list sufficient.
- **"Don't ask" directive — rejected.** Risks uncontrolled writes to user files.
- **Verification Checkpoint — rejected.** Near-tautological with existing "Write tests". Risk of performative compliance. CODE REVIEW step already serves as verification.

**Key architectural insight:** The global prompt works because it is **workflow mechanics**, not **behavioral coaching**. Both surviving changes are routing/trigger rules, not behavioral aspirations.

### Decision

Two compact additions (~70 tokens total):
1. Correction persistence trigger with slim routing list — routes corrections to existing persistence layers
2. Re-plan signs — concrete triggers that complement Claude Code's vague native instruction (additive, not duplicative)

## Solution

Two additions to `templates/base/global-CLAUDE.md`. Both minimal, both follow the existing prompt's pattern of concrete, mechanical rules.

### Change 1: Correction Persistence Trigger

**Where:** Development Flow section, after the Complexity Check.

```markdown
### After User Corrections

When the user corrects a mistake or shares project knowledge that should survive `/clear`,
persist it to the appropriate location:
- Project facts and constraints → Recent Decisions
- Personal preferences → User Instructions (global CLAUDE.md)
- Session-specific context → Private Note

Mention briefly: "Noted in [location]."
```

### Change 2: Signs to Re-Plan

**Where:** In the Complexity Check section, after the existing "After implementation" block.

```markdown
### Signs to Re-Plan

Stop and reassess your approach when:
- Third workaround for the same problem
- A discovery invalidates an earlier assumption
- Scope is growing significantly beyond the original task
```

**Design decisions:**
- ~70 tokens total permanent context cost (both changes combined)
- Slim routing list (3 lines) — concrete enough to act on, compact enough to not bloat
- No "don't ask" directive — Claude uses judgment about when to confirm
- Re-plan signs are concrete observable triggers, not a restatement of Claude's native instruction

## User Stories

### Story 1: Add Correction Persistence Trigger and Re-Plan Signs to global prompt
**Priority:** High

**Acceptance Criteria:**
- [x] Correction trigger added after Complexity Check in `templates/base/global-CLAUDE.md`
- [x] Re-plan signs added after "After implementation" block in Complexity Check
- [x] Content version bumped in `templates/VERSION`

### Story 2: Update documentation
**Priority:** Low

**Acceptance Criteria:**
- [x] CHANGELOG.md entry added
- [x] README content badge updated

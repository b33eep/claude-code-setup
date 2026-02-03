# Record 030: /design Command

## Status

Done

---

## User Guide

### What is /design?

A structured way to plan complex features before implementing them. Instead of jumping into code, you work through: Problem → Options → Solution → User Stories.

The result is a Record (markdown file) that documents your design decisions and breaks the work into implementable stories.

### When to use it?

| Use /design when... | Use /todo when... |
|---------------------|-------------------|
| Feature has multiple parts | Just need a reminder |
| Unsure how to implement | Quick idea for later |
| Need to evaluate options | Simple task |
| Architecture decision | - |

### Basic usage

```
/design "Add OAuth2 authentication"
```

Claude guides you through 5 steps:
1. **Problem** - What are we solving and why?
2. **Options** - What approaches exist? (skipped if obvious)
3. **Solution** - How will we do it?
4. **Stories** - Break it into implementable pieces
5. **Finalize** - Record is complete, ready to implement

After each step, the Record is updated. You can see progress at any time.

### Get a review

At any point, request feedback on your design:

```
/design --review
```

This invokes code-review-ai to review what you have so far and suggest improvements. Requires the code-review-ai plugin.

### Resume after /clear

If you /clear mid-design, resume with:

```
/design --continue
```

Or just run `/design` - it detects incomplete designs and asks if you want to continue.

### Implementing stories

When you start implementing a story from your design, Claude checks if it needs a mini-design:

- **Simple story** → Implement directly
- **Complex story** → Claude suggests: "This has multiple approaches. Quick mini-design?"

You can always skip with "just implement it". Implementation notes are saved to the Record.

### Example workflow

```
You: /design "Add user notifications"

Claude: Let's design this. What problem are we solving?
You: Users miss important updates because there's no notification system.

Claude: [Creates Record, asks about options...]
...

Claude: Design complete! Record 031 created with 3 stories:
1. Story 1: Email notifications (High)
2. Story 2: In-app notifications (High)
3. Story 3: Notification preferences (Medium)

You: Let's implement Story 1

Claude: [Checks complexity] This needs a library choice (SendGrid vs SES vs Resend).
        Quick mini-design? [Yes / Just implement it]

You: Yes

Claude: Options:
        - SendGrid: Mature, good docs, $15/mo for 50k emails
        - AWS SES: Cheapest, but complex setup
        - Resend: Simple API, good free tier, modern DX

        Which fits best?

You: Resend - we want simple and the free tier is enough for now

Claude: [Implements email notifications with Resend]
        [Updates Record with Implementation Notes]

        Story 1 complete. Implementation Notes saved:
        - Considered: SendGrid vs AWS SES vs Resend
        - Chose: Resend because simple API, good free tier
```

---

## Problem

Complex features/tasks are often planned without structure:
- No clear process from Problem → Solution → Implementation
- Plans are freeform, important aspects get forgotten
- No clear user stories with acceptance criteria
- Context is lost after /clear

## Why isn't this solved today?

| Tool | What it does | What's missing |
|------|--------------|----------------|
| Plan Mode (built-in) | Claude plans before implementing | No structured format, no record |
| /todo | Captures tasks for later | No design process, no stories |
| Records (manual) | Stores decisions | Manual effort, no workflow |

**Gap:** No command that provides a structured design workflow with persistent output.

## Proposed Solution: /design Command

### Workflow (5 Steps)

The record is created immediately and grows incrementally after each step. This allows:
- Review and course-correction at any point
- Early abort if problem is unclear
- User always sees current state

```
User: /design "OAuth2 authentication"

┌─────────────────────────────────────────────────────────────┐
│  1. PROBLEM                                                 │
│     - What is the problem?                                  │
│     - Why does it need to be solved?                        │
│     - What happens if we do nothing?                        │
│                                                             │
│     → Record created with Problem section                   │
│     → Status: "Designing"                                   │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  2. OPTIONS (conditional)                                   │
│     If multiple approaches exist:                           │
│     - Option A: [Description] + Pro/Con                     │
│     - Option B: [Description] + Pro/Con                     │
│     - Decision: [X] because [reason]                        │
│                                                             │
│     If single obvious approach:                             │
│     - Skip to Solution (note: "no alternatives considered") │
│                                                             │
│     → Record updated with Options section (or skipped)      │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  3. SOLUTION                                                │
│     - High-level approach                                   │
│     - Architecture / Design                                 │
│     - Key decisions                                         │
│                                                             │
│     → Record updated with Solution section                  │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  4. USER STORIES                                            │
│     - Value-driven: Most important first                    │
│     - Risky/difficult early (fail fast)                     │
│     - Each story with acceptance criteria                   │
│     - Stories are independently implementable               │
│                                                             │
│     → Record updated with User Stories section              │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  5. FINALIZE                                                │
│     - Status in CLAUDE.md: "Feature | Designed | Record X"  │
│     - Record status: "Designed"                             │
│     - Ready for implementation                              │
└─────────────────────────────────────────────────────────────┘
```

### Optional Review: --review Flag

At any point, user can request a review:

```
/design --review
```

This invokes code-review-ai to:
- Review the current state of the design record
- Provide feedback on completed sections
- Suggest improvements before continuing
- Review agent knows what steps remain and provides context-aware feedback

**Works on:**
- Active design session (during /design)
- Incomplete records after /clear (same detection as --continue)

**After review:** User is prompted to continue the design workflow.

**If code-review-ai not installed:** Skip with hint to install plugin.

### Record Evolution

| After Step | Record Contains |
|------------|-----------------|
| 1. Problem | Problem section, Status: Designing |
| 2. Options | + Options Considered + Decision (or skipped if single approach) |
| 3. Solution | + Solution section |
| 4. User Stories | + User Stories with AC |
| 5. Finalize | Status: Designed, CLAUDE.md updated |

### Output: Record Format

```markdown
# Record {NNN}: {Feature Title}

## Status

Designing | Designed | In Progress | Done

## Problem

[What is the problem? Why does it need to be solved?]

## Options Considered

### Option A: [Name]
- **Approach:** [Description]
- **Pros:** [Advantages]
- **Cons:** [Disadvantages]

### Option B: [Name]
...

### Decision

[Chosen option] because [reasoning].

## Solution

[High-level design, architecture, key decisions]

## User Stories

### Story 1: [Title]
**As a** [role]
**I want** [feature]
**So that** [benefit]

**Acceptance Criteria:**
- [ ] AC 1
- [ ] AC 2
- [ ] AC 3

**Priority:** High | Medium | Low
**Status:** Pending | In Progress | Done

### Story 2: [Title]
...
```

## Integration

### With /todo

- /todo and /design are separate commands with clear purposes
- /todo = quick capture to Future table (simplified, no Records)
- /design = full design workflow with Record and Stories
- If user runs /todo with something complex: hint to use /design

### With code-review-ai

- Opt-in via `/design --review` at any point
- Reviews current state, knows remaining steps
- If not installed: Skip with hint

### With /wrapup

- /wrapup updates story status in record
- /wrapup updates status in CLAUDE.md

### With /catchup

- /catchup loads records with status "Designing", "Designed" or "In Progress"
- User sees where to continue

## Tradeoffs

| Aspect | Pro | Con |
|--------|-----|-----|
| Structured 5-step process | Consistency, nothing forgotten | Some overhead |
| Opt-in reviews | Flexible, no hard dependency | User must remember to review |
| User stories with AC | Clearly implementable, testable | More upfront work |
| Record creation | Persisted, survives /clear | More files |

## When to Use /design vs /todo

| Situation | Command | Why |
|-----------|---------|-----|
| "Remember to do X later" | /todo | Quick capture, backlog |
| Idea for future | /todo | Just a reminder |
| Bug fix | Just do it | No tracking needed |
| Config change | Just do it | No tracking needed |
| Feature with multiple stories | /design | Needs structured planning |
| Architecture decision | /design | Needs options, tradeoffs |
| Unsure how to implement | /design | Needs exploration |

### Clear Separation

```
/todo = CAPTURE
- Quick backlog entry
- "Don't forget this"
- No design, no stories
- Future table only

/design = PLAN
- Structured 5-step process
- Problem → Options → Solution → Stories → Finalize
- Review opt-in with --review
- Record with full context
```

## User Stories for /design Implementation

### Story 1: Basic /design Workflow with Iterative Record
**As a** developer
**I want** to run `/design "feature name"` and get a structured design process
**So that** I have a clear plan before implementing

**Acceptance Criteria:**
- [x] /design starts with problem question
- [x] Record is created immediately after step 1 (Problem)
- [x] Record is updated after each subsequent step
- [x] User can see record growing incrementally
- [x] Guides through all 5 steps
- [x] Updates CLAUDE.md status at end (Designed)

**Priority:** High
**Status:** Done
**Updated:** 2026-02-03

### Story 2: Opt-in Review with --review Flag
**As a** developer
**I want** to request a review at any point during design
**So that** I get feedback when I need it

**Acceptance Criteria:**
- [x] `/design --review` invokes code-review-ai on current record
- [x] Review agent sees current state and knows remaining steps
- [x] Feedback is shown to user (not stored in record by default)
- [x] If plugin not installed: Skip with hint
- [x] User can continue design after review

**Priority:** High
**Status:** Done
**Updated:** 2026-02-03

### Story 3: Simplify /todo Command
**As a** developer
**I want** /todo to be a quick capture tool for the backlog
**So that** I have a clear separation between capturing ideas and designing solutions

**Acceptance Criteria:**
- [x] /todo only adds entries to Future table (no Record creation)
- [x] /todo is for quick capture: "remember this for later"
- [x] Complex items get hint: "Consider using /design for this"
- [x] Update /todo command documentation
- [x] Clear guidance: /todo = capture, /design = plan

**Priority:** Medium
**Status:** Done
**Updated:** 2026-02-03

### Story 4: Resume Incomplete Design
**As a** developer
**I want** to resume an incomplete design after /clear
**So that** I can continue where I left off

**Acceptance Criteria:**
- [x] `/design --continue` or `/design` detects incomplete design
- [x] Shows current state and remaining steps
- [x] User can continue from where they stopped
- [x] Works across sessions (record persists)

**Priority:** Medium
**Status:** Done
**Updated:** 2026-02-03

### Story 5: Story Implementation with Optional Mini-Design
**As a** developer
**I want** Claude to assess if a story needs a mini-design before implementing
**So that** complex stories get proper solution design without over-engineering simple ones

**Acceptance Criteria:**
- [x] When user starts implementing a story, Claude automatically assesses complexity
- [x] Claude suggests mini-design if complexity indicators are met
- [x] User can skip mini-design ("just implement it")
- [x] Simple stories: proceed directly to implementation
- [x] Complex stories: mini-design first (Options → Solution → then implement)
- [x] Implementation Notes are appended to the story in the record (not lost after /clear)

**Complexity Indicators (auto-trigger mini-design):**
- Multiple valid implementation approaches (2+ distinct paths)
- Needs library/tool choice
- Architecture impact (changes span 3+ files in different modules)
- New external dependency required

**Skip mini-design when:**
- Straightforward CRUD/UI change
- Clear single approach
- User explicitly says "just implement it"

**Implementation Notes format (appended to story):**
```markdown
**Implementation Notes:**
- Considered: [Option A] vs [Option B]
- Chose: [Option] because [reason]
```

**Priority:** Medium
**Status:** Done
**Updated:** 2026-02-03

## Decisions

### Stories stay in Record only
Stories are part of the design record, not duplicated to Future table. The record IS the plan.

### Interactive Q&A approach
/design is interactive: Claude asks questions, user answers, Claude drafts each section. User approves or refines before moving to next step.

### Review feedback is transient
`/design --review` shows feedback but does not persist it to the record by default. User incorporates feedback manually by updating sections.

### Options step is conditional
If only one viable approach exists, skip Options and go directly to Solution. Note in Solution: "No alternatives considered because [reason]."

### Mini-design is auto-triggered
When implementing a story, Claude automatically assesses complexity and suggests mini-design if needed. User can always skip with "just implement it." Implementation notes are persisted in the record.

### No explicit cancel/abort
Incomplete designs remain with Status: "Designing" until user resumes (--continue) or manually deletes the record. No --cancel flag needed.

## Related

- [Record 018](018-todo-command.md) - /todo Command
- [Record 026](026-external-plugins.md) - External Plugins (code-review-ai)
- [Record 013](013-skill-creator.md) - Skill Creator (similar workflow command)

# Design: Structured Feature Design

A structured way to plan complex features before implementing. Works through: Problem → Options → Solution → Stories → Finalize.

The result is a Record (markdown file) that documents design decisions and breaks work into implementable stories.

## Usage

```
/design "Feature name"     # Start new design
/design --continue         # Resume incomplete design
/design --review           # Get feedback on current design (requires comprehensive-review)
```

## When to Use /design vs /todo

| Use /design when... | Use /todo when... |
|---------------------|-------------------|
| Feature has multiple parts | Just need a reminder |
| Unsure how to implement | Quick idea for later |
| Need to evaluate options | Simple task |
| Architecture decision | - |

## Tasks

### Prerequisites

- If no project CLAUDE.md found: Tell user to run `/init-project` first
- If no `docs/records/` directory: Create it

### Handle Arguments

**No arguments:**
1. Check for incomplete designs (Records with Status: "Designing")
2. If found: Show state summary, offer to resume (see "Resume Design Workflow")
3. If none: Ask "What feature do you want to design?"

**With feature name:**
1. Check if a Record for this feature already exists (search by title)
2. If found with Status "Designing": Ask "Resume existing design?" or "Start fresh?"
3. If found with Status "Designed/In Progress/Done": Ask "Feature already has Record [NNN]. Create new design anyway?"
4. Start new design workflow for the given feature

**--continue flag:**
1. Find incomplete designs (Records with Status: "Designing")
2. If multiple found: Show list, ask "Which design to continue?"
3. If single found: Show state summary, resume from current step
4. If none: "No incomplete design found. Start new with /design 'feature name'"

See "Resume Design Workflow" section below for details.

**--review flag:**
1. Find current design (active session or incomplete Record)
2. If multiple incomplete designs: Ask "Which design to review?" with list
3. If no design found: "No design to review. Start with /design 'feature name'"
4. If comprehensive-review plugin not installed: "Install comprehensive-review plugin for design reviews: /claude-code-setup → External Plugins"
5. If plugin installed: Invoke review agent (see Review Agent section below)
6. Show feedback to user (do not store in Record)
7. After review: Prompt with explicit next step (see After Review section)

---

## Review Agent Integration

When `/design --review` is invoked, use the `comprehensive-review:architect-review` agent.

### Finding the Design to Review

1. If in active design session: Review current Record
2. If multiple incomplete designs exist: Ask user which one to review
3. If single incomplete design: Review that Record
4. If no design found: "No design to review. Start with `/design 'feature name'`"

### Determine Current Step

Check which sections exist in the Record (see "Step Inference for Resume" in State Tracking section for full logic):

| Sections Present | Phase | Next Step |
|------------------|-------|-----------|
| Problem only | Early | Step 2: Options |
| Problem + Options + Decision | Mid | Step 3: Solution |
| Problem + Solution (no Options) | Mid | Step 4: Stories (Options skipped) |
| Problem + Solution + Stories | Late | Step 5: Finalize |

### Review Prompt

Pass this context to the review agent:

```
Review this design record for [Feature Name].

Current state: [Phase] - [List completed sections]
Next step: Step N ([Step Name])
Remaining: [List remaining steps]
Tech Stack: [From project CLAUDE.md]

Record content:
[Full Record content]

Evaluate:
1. Problem clarity - Is the problem well-defined? Is the "why" clear?
2. Options analysis - Are alternatives properly considered? (if applicable)
3. Solution completeness - Does the solution address the problem?
4. Story quality:
   - Are stories independently implementable?
   - Are acceptance criteria clear and testable?
   - Are stories ordered by value and risk?
   - Any hidden dependencies between stories?
5. Architecture & design - Are patterns appropriate? Tech stack alignment?
6. Missing considerations - Security, performance, error handling, edge cases?

Focus feedback on completed sections. For in-progress sections, suggest improvements.
Be actionable: "Consider adding..." not "You forgot..."
Skip praise; focus on what can be improved.
```

### After Review

Display feedback, then prompt with explicit next step:

```
Review complete. Feedback is NOT stored in the Record.

Current position: Step [N] ([Step Name])
Next: Step [N+1] ([Next Step Name])

Ready to continue?
[Yes] → Continue to Step [N+1]
[No]  → Save and exit (resume with `/design --continue`)
```

**If Yes:** Resume with the next step question (e.g., "Let's define the solution...")
**If No:** Confirm save: "Design saved as docs/records/[NNN]-[slug].md. Resume anytime with `/design --continue`"

### Error Handling

If review agent fails:
1. Show: "Review could not be completed: [error]"
2. Prompt: "Continue design without review? [Yes / No]"

---

## Workflow: 5 Steps

The Record is created after Step 1 and updated after each subsequent step. User sees progress incrementally.

### Step 1: Problem

Ask the user:
```
Let's design: [Feature Name]

First, let's understand the problem.
- What problem are we solving?
- Why does it need to be solved?
- What happens if we do nothing?
```

Wait for user response. Then:

1. **Create Record immediately** with next available number in `docs/records/`
2. Write Problem section to Record
3. Set Status: "Designing"
4. Confirm to user: "Record [NNN] created. Problem captured."

### Step 2: Options (Conditional)

Assess if multiple approaches exist:

**If multiple viable approaches:**
Ask the user:
```
What approaches have you considered? Let's evaluate options.

For each option, we'll note:
- Approach description
- Pros
- Cons
```

Discuss options with user. Then:
1. Update Record with Options Considered section
2. Ask: "Which option do you prefer and why?"
3. Update Record with Decision
4. Confirm: "Options documented. Decision: [chosen option]"

**If single obvious approach:**
1. Skip to Step 3
2. Note in Solution: "No alternatives considered - [reason]"

### Step 3: Solution

Ask the user:
```
Let's define the solution.
- How will we implement this?
- What's the high-level architecture?
- Any key technical decisions?
```

Wait for user response. Then:
1. Update Record with Solution section
2. Confirm: "Solution documented."

### Step 4: User Stories

**Before writing stories:** If `~/.claude/skills/user-stories/SKILL.md` exists, read it. Apply INVEST criteria and Given-When-Then acceptance criteria patterns from the skill.

Ask the user:
```
Let's break this into implementable stories.

Good stories are:
- Value-driven (most important first)
- Risky/difficult early (fail fast)
- Independently implementable
- Have clear acceptance criteria

What's the first/most important story?
```

Work through stories iteratively:
1. For each story, capture: Title, As a/I want/So that, Acceptance Criteria, Priority
2. Validate each story against INVEST criteria (if skill loaded)
3. Ask: "Any more stories?" until user says no
4. Update Record with all User Stories
5. Confirm: "Stories documented: [list titles]"

### Step 5: Finalize

1. Update Record Status: "Designed"
2. Update project CLAUDE.md:
   - Add to Current Status table: `| [Feature] | Designed | [Record NNN](docs/records/NNN-feature.md) |`
   - Or update existing row if feature was already listed
3. Show final summary:
   ```
   Design complete! Record [NNN] created.

   Stories ready for implementation:
   1. [Story 1 title] (Priority)
   2. [Story 2 title] (Priority)
   ...

   Start implementing with: "Let's implement Story 1"
   ```

---

## Record Format

```markdown
# Record {NNN}: {Feature Title}

## Status

Designing | Designed | In Progress | Done

---

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

---

## Record Numbering

Scan `docs/records/` for highest existing number and increment:

```
docs/records/
├── 028-update-notifications.md
├── 029-documentation-user-perspective.md
└── 030-design-command.md
→ Next: 031-{feature-slug}.md
```

Slug: lowercase, hyphens, max 30 chars. Truncate long names to key terms.

Examples:
- "Add OAuth2 Authentication" → `031-oauth2-authentication.md`
- "Add comprehensive user notification system with multi-channel support" → `031-user-notifications.md`

---

## State Tracking

Progress is tracked via Record Status field:

| Status | Meaning |
|--------|---------|
| Designing | Design in progress (Steps 1-4) |
| Designed | Design complete, ready to implement |
| In Progress | Implementation started |
| Done | Feature implemented |

To find incomplete designs:
```bash
grep -l "^Designing" docs/records/*.md
```

### Step Inference for Resume

When resuming, determine current step by checking which sections exist in the Record:

| Sections Present | Current Step | Notes |
|------------------|--------------|-------|
| Problem only | Step 2 (Options) | |
| Problem + Options (no Decision) | Step 2 (Options) | Still evaluating |
| Problem + Options + Decision | Step 3 (Solution) | Options complete |
| Problem + Solution (no Options) | Step 4 (Stories) | Options was skipped |
| Problem + Options + Decision + Solution | Step 4 (Stories) | |
| Problem + Solution + User Stories (no Options) | Step 5 (Finalize) | Options skipped, stories done |
| Problem + Options + Decision + Solution + User Stories | Step 5 (Finalize) | All sections complete |

**Key rule:** If Solution exists but Options does not → Options was intentionally skipped (single obvious approach). Skip to Step 4.

**Progress display for skipped steps:**
```
✓ Step 1: Problem - defined
⊘ Step 2: Options - skipped (single approach)
→ Step 3: Solution - current step
```

---

## Resume Design Workflow

When `/design --continue` or `/design` (without args) detects incomplete designs:

### Finding Incomplete Designs

```bash
grep -l "^Designing" docs/records/*.md
```

### Multiple Incomplete Designs

If multiple found, show list and ask:

```
Found 2 incomplete designs:

1. Record 031: Add user notifications (Step 3: Solution)
2. Record 032: Implement caching (Step 2: Options)

Which design do you want to continue? [1/2]
```

### Single Incomplete Design

Show state summary and confirm:

```
Found incomplete design: "Add user notifications" (Record 031)

Progress:
✓ Step 1: Problem - defined
✓ Step 2: Options - evaluated, decided on email + in-app
→ Step 3: Solution - current step
  Step 4: Stories
  Step 5: Finalize

Continue from Step 3? [Yes / Start over / Cancel]
```

**If Yes:** Resume with the step's question (e.g., "Let's define the solution...")
**If Start over:** Clear Record content, restart from Step 1
**If Cancel:** Exit without changes

### Resume Step Questions

When resuming, use the same questions as the original workflow:

| Step | Resume Question |
|------|-----------------|
| Step 2 (Options) | "Let's evaluate options. What approaches have you considered?" |
| Step 3 (Solution) | "Let's define the solution. How will we implement this?" |
| Step 4 (Stories) | "Let's break this into stories. What's the first/most important story?" |
| Step 5 (Finalize) | "Let's finalize. Ready to mark this design as complete?" |

### No Arguments Behavior

When user runs `/design` without arguments:

1. Check for incomplete designs
2. If found: Same flow as `--continue` (show state, offer to resume)
3. If none: Ask "What feature do you want to design?"

This makes resuming seamless - user doesn't need to remember `--continue`.

### Error Handling

**Corrupted Record (missing required sections):**
```
Record 031 found but appears corrupted (missing Problem section).
Start fresh? [Yes / No]
```
If Yes: Rename to `031-feature.backup.md`, create new Record.

**Record file not found:**
```
Record 031 was detected but file is missing. It may have been deleted.
Create new design? [Yes / No]
```

**Invalid choice when multiple designs:**
```
Found 2 incomplete designs:
1. Record 031: Notifications
2. Record 032: Caching

Which design? [1/2]
> 3
Please enter 1 or 2.
```

**Empty Record file:**
```
Record 031 exists but is empty or unreadable.
Overwrite with new design? [Yes / No]
```

---

## Integration with Other Commands

### /catchup
- Loads Records with Status "Designing", "Designed", or "In Progress"
- User sees where to continue (design or implementation)

### /wrapup
- Updates story status in Record if implementation happened
- Updates Current Status table in project CLAUDE.md

### /todo
- /todo = quick capture (Future table)
- /design = structured planning (Record with Stories)
- If user runs /todo with something complex: hint to use /design

---

## Examples

### Starting a New Design

```
User: /design "Add user notifications"

Claude: Let's design: Add user notifications

First, let's understand the problem.
- What problem are we solving?
- Why does it need to be solved?
- What happens if we do nothing?

User: Users miss important updates. They have to manually check
      the app. If we do nothing, engagement drops.

Claude: Record 031 created. Problem captured.

Let's consider options. What approaches have you thought about?
...
```

### Resuming After /clear

```
User: /design --continue

Claude: Found incomplete design: "Add user notifications" (Record 031)
        Currently at: Step 3 (Solution)

        Let's continue. How will we implement this?
...
```

### Quick Design (Obvious Approach)

```
User: /design "Fix pagination in user list"

Claude: Let's design: Fix pagination in user list

First, what problem are we solving?

User: List shows all 10k users at once. Page freezes.

Claude: Record 032 created. Problem captured.

This seems like a straightforward pagination fix.
Should we evaluate different pagination approaches,
or go directly to the solution?

User: Just standard offset pagination is fine.

Claude: Got it. No alternatives considered - standard approach.

Let's define the solution...
```

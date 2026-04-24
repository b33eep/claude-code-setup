# Writing Descriptions

The `description` field decides whether your skill ever gets used. Claude reads it on every request to pick from dozens of available skills. A vague description means the skill never triggers. A precise one means it triggers reliably without false positives.

## The formula

> **[What it does]** + **[When to use it, with trigger phrases]** + *(optional)* **[Key capabilities]**

Every good description has the first two parts. Complex skills add the third.

## Anatomy of a good description

```yaml
description: Analyzes Figma design files and generates developer handoff documentation. Use when the user uploads .fig files, asks for "design specs", "component documentation", or "design-to-code handoff".
```

Breakdown:

- **What it does:** "Analyzes Figma design files and generates developer handoff documentation."
- **When to use it:** "Use when the user uploads .fig files, asks for 'design specs', 'component documentation', or 'design-to-code handoff'."
- **Trigger phrases** (bolded for clarity): `.fig files`, `design specs`, `component documentation`, `design-to-code handoff`

Claude now has four concrete signals to match against. A user who says "Can you give me design specs for this?" triggers the skill even without knowing the skill exists.

## Trigger phrases — the key ingredient

Trigger phrases are **exact words a user might actually say**. Not what the skill does internally — what the user calls it.

### Good trigger phrases

- Domain-specific jargon: `"sprint planning"`, `"DNS propagation"`, `"PR review"`
- Product names: `"Linear task"`, `"Figma export"`, `"Sentry issue"`
- Task verbs + objects: `"onboard customer"`, `"generate report"`, `"deploy to staging"`
- File types: `.csv`, `.fig`, `Dockerfile`
- Question forms: `"how do I deploy"`, `"what's the review process"`

### Bad trigger phrases

- Generic verbs alone: `"help"`, `"analyze"`, `"process"`
- Internal implementation details: `"calls the Linear API"`, `"uses GPT-4"`
- Your team's internal jargon the user doesn't know: `"PLA-456 workflow"`

### Rule of thumb

Before committing a description, ask yourself: *"If a user had never heard of this skill and needed its help, what exact words would they type?"* Those are your trigger phrases.

## Good examples

**Specific, actionable, clear triggers:**

```yaml
description: Manages Linear project workflows including sprint planning, task creation, and status tracking. Use when the user mentions "sprint", "Linear tasks", "project planning", or asks to "create tickets".
```

```yaml
description: End-to-end customer onboarding for PayFlow. Handles account creation, payment setup, and subscription management. Use when the user says "onboard new customer", "set up subscription", or "create PayFlow account".
```

```yaml
description: Analyzes CSV files for statistical patterns including regression, clustering, and outlier detection. Use when the user uploads a .csv file and asks for statistical modeling, not for simple data exploration (use `data-viz` skill for that).
```

Note the last one — it includes **negative triggers** ("not for simple data exploration") to prevent overtriggering. More on this below.

## Bad examples

### Too vague

```yaml
description: Helps with projects.
```

No what, no when, no triggers. Will never load reliably.

### Missing triggers

```yaml
description: Creates sophisticated multi-page documentation systems with cross-references and search indexing.
```

What it does is clear. When to use it? Unclear. No user-facing phrases.

### Too technical, no user framing

```yaml
description: Implements the Project entity model with hierarchical relationships via the ProjectHub GraphQL API.
```

This describes the implementation. Claude (and users) don't think in implementation terms. Reframe around user intent:

```yaml
description: Creates projects in ProjectHub with nested sub-projects and team assignments. Use when the user says "create a project", "set up a new workspace", or "organize tasks by team".
```

### Overly long feature list

```yaml
description: Comprehensive tool for managing projects, tasks, milestones, sprints, assignees, labels, priorities, deadlines, comments, attachments, notifications, integrations, reports, exports, imports, and more.
```

Over 1024 chars is rejected by the parser. Even short versions that list every capability dilute the trigger signal. Pick 2–4 key triggers; list the rest in SKILL.md.

## Negative triggers

When two skills overlap, specify what each is NOT for:

```yaml
description: Advanced statistical analysis for CSV files. Use for regression, clustering, outlier detection, and time-series modeling. Do NOT use for simple data exploration or visualization — use `data-viz` skill for that.
```

Negative triggers prevent overtriggering. Useful when:

- Two of your skills address adjacent domains
- A general-purpose skill and a specialized one both could match
- A user's casual phrasing might match your skill when they actually wanted a different tool

## Length budget

**Under 1024 characters** is a hard limit — the parser rejects longer.

In practice, aim for **30–80 words**. Enough to include what + when + 2–4 trigger phrases, not enough to drift into implementation details.

| Length | Works for |
|---|---|
| 20–40 words | Simple command skills with one clear purpose |
| 40–80 words | Most skills — what + when + 2–4 triggers + (optional) negative trigger |
| 80–120 words | Complex skills with many sub-capabilities |
| 120+ words | Probably too long — pick triggers, move details to SKILL.md |

## Testing your description

Before shipping, in a fresh Claude conversation:

1. Ask Claude: "When would you use the `<skill-name>` skill?"
2. Claude quotes back (roughly) the description
3. Verify it quotes back **the trigger phrases**

If Claude doesn't quote the triggers, Claude won't use them for matching. Rewrite.

Then test real user queries:

- **Should trigger:** 5 paraphrased versions of each use case — does the skill load?
- **Should NOT trigger:** 5 unrelated queries, 5 queries that touch the domain but aren't the skill's job — does the skill stay quiet?

If triggering is off, the description is the first suspect, not the SKILL.md body.

## Iterating

Descriptions are living text. When you notice:

- **Undertriggering** (skill doesn't load when it should) → add specificity, include more trigger phrases, add technical keywords users might search for
- **Overtriggering** (skill loads when it shouldn't) → add negative triggers, be more specific about scope, narrow the phrase list

Revise, test, repeat. Most skills need 2–3 description revisions before they settle.

## Complete contrast example

**Before (undertriggers, no concrete triggers):**

```yaml
description: A skill for project management.
```

**After (concrete, actionable, complete):**

```yaml
description: Manages Linear projects end-to-end — sprint planning, task creation, status tracking, and burndown reporting. Use when the user says "sprint planning", "create tasks in Linear", "update Linear status", or asks about team velocity. Do NOT use for one-off questions — query Linear directly for those.
```

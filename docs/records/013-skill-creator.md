# Record 013: Skill Creator

**Status:** Accepted
**Date:** 2026-01-25

## Context

claude-code-setup allows users to create custom skills in `~/.claude/custom/skills/`. However, there's no guidance on how to create a well-structured skill. Users must:

1. Know the SKILL.md format (frontmatter fields, structure)
2. Understand the difference between `command` and `context` skills
3. Know about `applies_to` for context skills
4. Figure out where to save the skill

This creates friction for users who want to extend their setup with personal or company-specific skills.

**Inspiration:** [AJBcoding/claude-skill-eval](https://github.com/AJBcoding/claude-skill-eval/tree/main/skills/skill-creator) has a skill-creator skill. Their approach is comprehensive but designed for a different skill format (no `type`, no `applies_to`, includes scripts/references/assets directories).

## Decision

Create a `/skill-creator` command skill adapted for claude-code-setup's simpler format.

### Target Audience

**End-users** of claude-code-setup who want to create custom skills, not maintainers.

Use cases:
- Company-specific style guides or workflows
- Personal productivity skills (e.g., `/deploy-my-app`)
- Domain-specific context skills (e.g., `my-framework-standards`)

### Key Design Principle

**Example-driven approach** for high-quality results.

Instead of asking "What should the skill do?" (abstract, leads to vague skills), ask "Give me 2-3 concrete examples of how you'd use this skill" (practical, leads to useful skills).

### Skill Format (claude-code-setup)

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Skill identifier (kebab-case) |
| `description` | Yes | What the skill does (1-2 sentences) |
| `type` | Yes | `command` or `context` |
| `applies_to` | Context only | Tech stacks that trigger auto-load |

## Implementation

### Flow

```
/skill-creator
     │
     ▼
┌─────────────────────────────────────┐
│ 1. TYPE                             │
│    Command or Context?              │
└─────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────┐
│ 2. EXAMPLES                         │
│    "Give 2-3 concrete use cases"    │
│    (Core step for quality)          │
└─────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────┐
│ 3. ANALYSIS                         │
│    Claude identifies:               │
│    - Name suggestion                │
│    - Patterns/workflows             │
│    - applies_to (for context)       │
└─────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────┐
│ 4. CONTENT                          │
│    Option A: Claude generates draft │
│    Option B: User provides content  │
│              → Claude reviews       │
└─────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────┐
│ 5. REVIEW & REFINE                  │
│    User approves or requests changes│
│    (as many iterations as needed)   │
└─────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────┐
│ 6. SAVE                             │
│    ~/.claude/custom/skills/{name}/  │
└─────────────────────────────────────┘
```

### Example Session (Command Skill)

```
User: /skill-creator

Claude: What type of skill do you want to create?
        1. Command skill - invoked explicitly with /skill-name
        2. Context skill - auto-loads based on project's tech stack

User: 1

Claude: Give me 2-3 concrete examples of how you'd use this skill.
        Format: "I say X and expect Y"

User: - "Deploy to staging" → push to staging branch, SSH to server, run deploy script
      - "Deploy to prod" → same but with confirmation prompt first
      - "Rollback" → revert to previous deployment

Claude: I see a deployment workflow pattern with multiple environments.

        Suggested name: deploy-workflow

        Should I generate the skill content, or do you want to provide it?

User: Generate it

Claude: Here's the draft:

        ---
        name: deploy-workflow
        description: Deploy to staging/production environments with rollback support
        type: command
        ---

        # Deploy Workflow

        ## Commands

        ### Deploy to Staging
        1. Push current branch to staging
        2. SSH to staging server
        3. Run deploy script

        ### Deploy to Production
        1. Confirm with user before proceeding
        2. Push current branch to production
        3. SSH to production server
        4. Run deploy script

        ### Rollback
        1. Identify previous deployment
        2. Revert to previous state

        ---

        Does this look good? Any changes needed?

User: Add a step to run tests before deploying

Claude: Updated. Creating skill...

        Created: ~/.claude/custom/skills/deploy-workflow/SKILL.md

        To use: /deploy-workflow
        To edit: Modify the SKILL.md file directly
```

### Example Session (Context Skill)

```
User: /skill-creator

Claude: What type of skill do you want to create?
        1. Command skill - invoked explicitly with /skill-name
        2. Context skill - auto-loads based on project's tech stack

User: 2

Claude: Give me 2-3 concrete examples of how this skill should guide Claude.
        Format: "When doing X, Claude should Y"

User: - When writing API endpoints, use our standard response format
      - When handling errors, use our custom exception classes
      - When writing tests, follow our naming convention

Claude: I see an API standards pattern.

        Suggested name: company-api-standards
        Suggested applies_to: python, fastapi

        Add more tech stacks? (comma-separated, or press enter to continue)

User: django

Claude: Should I generate the skill content, or do you want to provide it?

User: I'll provide it

Claude: Paste your skill content (the instructions Claude should follow):

User: [pastes content]

Claude: Reviewing your content...

        Suggestions:
        - Add examples for the response format
        - Clarify exception class hierarchy

        Should I incorporate these suggestions?

User: Yes

Claude: Updated. Creating skill...

        Created: ~/.claude/custom/skills/company-api-standards/SKILL.md

        This skill will auto-load when your project's Tech Stack includes:
        python, fastapi, or django
```

### File Structure

```
skills/skill-creator/
└── SKILL.md
```

Output location:
```
~/.claude/custom/skills/{skill-name}/
└── SKILL.md
```

## Consequences

### Positive

- Lowers barrier for custom skill creation
- Example-driven approach leads to practical, high-quality skills
- Ensures correct format (frontmatter, type, applies_to)
- Flexible: Claude generates or user provides content
- Review step catches quality issues
- Documents skill conventions through usage

### Negative

- Another command skill to maintain
- Depends on user providing good examples
- Doesn't handle complex skills with external resources (scripts, assets)

### Not Included (Future Scope)

- Editing existing skills (user can edit SKILL.md directly)
- Skill validation/testing
- Script generation (scripts/, references/, assets/)
- Skill packaging/distribution

## Attribution

Inspired by [AJBcoding/claude-skill-eval skill-creator](https://github.com/AJBcoding/claude-skill-eval/tree/main/skills/skill-creator), adapted for claude-code-setup's simpler skill format.

# ADR-010: Improved Skill Auto-Loading

**Status:** Accepted
**Date:** 2026-01-24

## Context

ADR-007 introduced context skills with `type: context` and `applies_to` metadata. The global prompt says "skills are automatically loaded at session start based on Tech Stack."

### Problem

This instruction is too vague. Claude often forgets to load skills, requiring manual reminders.

**Example (actual conversation):**
```
User: Create test scenario 05-statusline.sh
Claude: [starts writing shell code without standards]
User: "ja, und nutze auch unser shell skill wenn du das umsetzt"
Claude: [reads shell skill, then writes proper code]
```

The user shouldn't need to remind Claude.

### Current State

**What exists:**
- Skills with metadata: `type: context`, `applies_to: [python, fastapi, ...]`
- Skills installed to `~/.claude/skills/`
- Vague instruction in global prompt

**What's missing:**
- Clear, actionable instructions WHEN to load WHICH skill
- Task-based loading (not just Tech Stack)
- Review agent receiving skills

## Decision

Improve the prompt in `templates/base/global-CLAUDE.md` with concrete instructions for three scenarios:

### 1. Session-Start Loading (Tech Stack)

**Current (vague):**
```markdown
Context skills are automatically loaded at session start based on Tech Stack.
```

**Proposed (concrete):**
```markdown
## Skill Loading

### At Session Start

After reading project CLAUDE.md, check the `Tech Stack:` field and load matching skills:

1. Parse Tech Stack (e.g., `Tech Stack: Python, FastAPI, PostgreSQL`)
2. For each skill in `~/.claude/skills/`:
   - Read SKILL.md frontmatter
   - If `type: context` AND any Tech Stack item appears in `applies_to` → READ the full SKILL.md
3. Custom skills (`~/.claude/custom/skills/`) override installed skills

Example:
- Project: `Tech Stack: Python, FastAPI`
- Skill: `applies_to: [python, fastapi, django]`
- Action: READ `~/.claude/skills/standards-python/SKILL.md`
```

### 2. Task-Based Loading

Load skills based on what you're about to do, regardless of Tech Stack:

```markdown
### Before Writing/Editing Code

Before writing or editing a file, load the matching skill if not already loaded:

| File Extension | Skill to Load |
|----------------|---------------|
| `.py` | `~/.claude/skills/standards-python/SKILL.md` |
| `.ts`, `.tsx`, `.js`, `.jsx` | `~/.claude/skills/standards-typescript/SKILL.md` |
| `.sh`, `.bash`, or Bash scripts | `~/.claude/skills/standards-shell/SKILL.md` |

Do this BEFORE writing code. Don't wait for a reminder.
```

### 3. Review Agent Integration

When spawning the review agent, include relevant skills in the prompt:

```markdown
### Code Review Agent

When using `code-review-ai:architect-review`, include the coding standards in the agent prompt:

1. Identify languages in the files being reviewed
2. Read the matching skills
3. Include skill content in the Task tool's prompt parameter

Example:
```
prompt: |
  Review these changes.

  Apply these coding standards:
  [paste content from standards-python/SKILL.md]
```

## File Changes

### templates/base/global-CLAUDE.md

Replace the current Skills section with the concrete instructions above.

### commands/catchup.md

Add skill loading as step 2 in the /catchup workflow:

```markdown
2. **Load context skills**
   - Check `Tech Stack:` in project CLAUDE.md
   - Load matching skills from `~/.claude/skills/`
   - Example: Tech Stack includes "Bash" → Read `standards-shell/SKILL.md`
```

This ensures skill loading happens at session start when /catchup runs.

**Before:**
```markdown
## Skills

Available skills for specialized tasks...
Context skills are automatically loaded at session start based on Tech Stack.
```

**After:**
```markdown
## Skill Loading

### At Session Start
[concrete instructions]

### Before Writing/Editing Code
[concrete instructions]

### Code Review Agent
[concrete instructions]
```

## Manual Test Scenarios

After implementing, verify with these scenarios:

### Test 1: Session-Start Loading
1. Open project with `Tech Stack: Python, FastAPI`
2. Start new session
3. **Expected:** Claude mentions reading standards-python or applies Python conventions without prompting

### Test 2: Task-Based Loading (Different Language)
1. Open project with `Tech Stack: Python`
2. Ask: "Create a shell script that runs the tests"
3. **Expected:** Claude reads standards-shell before writing, without reminder

### Test 3: Task-Based Loading (No Tech Stack Match)
1. Open project with `Tech Stack: Rust` (no Rust skill exists)
2. Ask: "Add a Python utility script"
3. **Expected:** Claude reads standards-python before writing

### Test 4: Review Agent
1. Make changes to Python files
2. Ask for code review
3. **Expected:** Review agent applies Python coding standards from skill

### Test 5: Custom Skill Override
1. Create `~/.claude/custom/skills/standards-python/SKILL.md` with custom content
2. Start session in Python project
3. **Expected:** Custom skill loaded instead of installed skill

## Alternatives Considered

| Alternative | Why Not |
|-------------|---------|
| Automated loading via hooks | claude-code-setup is config-only, no runtime code |
| Always load all skills | Context bloat, irrelevant noise |
| Keep current vague instruction | Doesn't work - proven by real usage |

## Consequences

### Positive
- Skills loaded when needed without reminders
- Review agent applies correct standards
- Clear instructions = more consistent behavior

### Negative
- Longer prompt in global-CLAUDE.md
- Still relies on Claude following instructions (no enforcement)
- May increase token usage (reading skills)

## Open Questions

1. Should Claude confirm which skills were loaded? (Transparency vs. noise)
2. How to handle multi-language files?
3. Should skill loading be logged somewhere?

## References

- [ADR-007: Coding Standards as Context Skills](007-coding-standards-as-skills.md)

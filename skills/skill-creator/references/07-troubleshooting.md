# Troubleshooting

Common issues during skill creation and after upload, with diagnosis and fixes.

## Skill won't upload / install

### `Error: "Could not find SKILL.md in uploaded folder"`

**Cause:** file not named exactly `SKILL.md` (case-sensitive).

**Fix:**

```bash
# Verify with exact listing
ls -la my-skill/
# Should show "SKILL.md", not "skill.md", "Skill.md", or "SKILL.MD"
```

Rename with `mv skill.md SKILL.md`. On macOS/APFS this usually works in one step (case-insensitive-but-case-preserving). On HFS+, Windows CI, or strict case-insensitive filesystems, use a two-step rename: `mv skill.md _tmp && mv _tmp SKILL.md`.

### `Error: "Invalid frontmatter"`

**Cause:** YAML formatting issue — usually missing delimiters, unclosed quotes, or XML brackets.

**Check:**

```yaml
# Wrong — missing delimiters
name: my-skill
description: Does things

# Wrong — unclosed quotes
name: my-skill
description: "Does things

# Wrong — XML brackets in a field value
description: Generates a <report> for the user

# Correct
---
name: my-skill
description: Does things properly
---
```

Paste the frontmatter into an online YAML validator if the error persists.

### `Error: "Invalid skill name"`

**Cause:** name has spaces, capitals, underscores, or uses a reserved prefix.

**Fix:**

```yaml
# Wrong
name: My Cool Skill
name: my_cool_skill
name: MyCoolSkill
name: claude-helper       # reserved prefix

# Correct
name: my-cool-skill
```

### Directory structure wrong

**Cause:** `SKILL.md` must be at the root of the skill folder, not nested.

```
# Wrong
my-skill/
└── docs/
    └── SKILL.md

# Correct
my-skill/
└── SKILL.md
```

## Skill doesn't trigger

**Symptom:** Skill never loads automatically even when the user's query seems to match.

### Step 1: ask Claude about the skill

In a fresh conversation:

> "When would you use the `my-skill` skill?"

Claude quotes back (roughly) the description. Check:

- Does Claude quote the trigger phrases? If not, they're not salient.
- Does Claude's summary match your intent, or has Claude reinterpreted?

### Step 2: review the description

Common issues:

- **Too generic** — `"Helps with projects"` never triggers for anything specific
- **Missing triggers** — the description explains the skill but doesn't include phrases users would actually say
- **Technical framing** — `"Implements the Project entity model"` doesn't match user intent ("create a project")
- **Description under ~100 chars** — as a rule-of-thumb, rarely enough room for what + when + 2–4 trigger phrases

**Fix:** rewrite per `03-writing-descriptions.md`.

### Step 3: check for competing skills

If two skills overlap, Claude picks the one whose description matches most closely. Narrow yours:

```yaml
# Before — too broad, loses to other general skills
description: Processes documents.

# After — narrow scope, wins the match
description: Processes PDF legal documents for contract review. Use when the user uploads a .pdf and asks for "contract review", "legal check", or "clause extraction".
```

### Step 4: verify the skill is enabled

- **Claude.ai:** Settings → Capabilities → Skills — toggle on
- **Claude Code:** skill file exists in `~/.claude/skills/` or `~/.claude/custom/skills/`

## Skill triggers too often

**Symptom:** Skill loads for unrelated queries.

### Fix 1 — add negative triggers

```yaml
# Before
description: Advanced data analysis for CSV files.

# After
description: Advanced data analysis for CSV files. Use for statistical modeling, regression, clustering. Do NOT use for simple data exploration — use `data-viz` skill instead.
```

### Fix 2 — be more specific about scope

```yaml
# Too broad
description: Processes documents.

# More specific
description: Processes PDF legal documents for contract review.
```

### Fix 3 — clarify the use case

```yaml
# Before
description: PayFlow payment processing.

# After
description: PayFlow payment processing for e-commerce checkout flows. Use specifically for online payment workflows, not for general financial queries or subscription management.
```

## Instructions not followed

**Symptom:** Skill loads but Claude doesn't follow the SKILL.md instructions — skips steps, hallucinates alternatives, or reverts to general reasoning.

### Cause 1: instructions too verbose

Long SKILL.md dilutes attention. Trim:

- Keep body concise
- Use bullets and numbered lists, not paragraphs
- Move detail to `references/` and link
- Target: well under 5000 words

### Cause 2: critical instructions buried

Put them at the top:

```markdown
## CRITICAL: Before calling `create_project`, verify:

- Project name is non-empty
- At least one team member assigned
- Start date is not in the past

If any check fails, stop and ask the user — do NOT guess a default.
```

Use `## Important` or `## Critical` headers. Repeat critical points in the troubleshooting section too if they keep getting missed.

### Cause 3: ambiguous language

```markdown
# Bad
Make sure to validate things properly.

# Good
CRITICAL: Before calling create_project, verify:
- Project name is non-empty
- At least one team member assigned
- Start date is not in the past
```

### Cause 4: language instruction where deterministic check is needed

For critical validations, bundle a script instead of relying on language interpretation. Language is probabilistic; code is deterministic.

```markdown
Before processing, validate the input:

```bash
python scripts/validate_input.py {filename}
```

Exit 0 = valid, exit non-zero = errors (printed to stderr).
Do NOT proceed if the script exits non-zero.
```

See `04-writing-instructions.md` → "When to reach for scripts."

### Cause 5: model "laziness"

Some tasks require explicit encouragement to do them thoroughly. **Important:** adding this to the **user prompt** is more effective than adding it to SKILL.md. Try the user-prompt approach first.

If the task needs encouragement baked in (because the skill is always invoked against high-stakes work), add it to SKILL.md as a last resort:

```markdown
## Performance notes

- Take your time to do this thoroughly
- Quality is more important than speed
- Do not skip validation steps
```

## MCP connection issues

**Symptom:** Skill loads but MCP calls fail.

### Checklist

1. **Verify MCP server is connected**
   - Claude.ai: Settings → Extensions → should show "Connected"
   - Claude Code: `claude mcp list` — check status column

2. **Check authentication**
   - API keys valid and not expired
   - Proper permissions / scopes granted
   - OAuth tokens refreshed if applicable

3. **Test MCP independently**
   - Ask Claude to call the MCP directly without the skill: "Use the [Service] MCP to fetch my projects"
   - If that fails, the issue is the MCP, not the skill

4. **Verify tool names**
   - Skill references correct MCP tool names
   - Check MCP server's documentation
   - Tool names are case-sensitive

## Large-context issues

**Symptom:** Skill loads feel slow, responses degrade over long conversations, tokens drain fast.

### Causes

- SKILL.md too large
- Too many skills enabled simultaneously
- All content inlined into SKILL.md instead of progressive disclosure

### Fixes

1. **Optimize SKILL.md size**
   - Move detailed docs to `references/`
   - Link from SKILL.md instead of inlining
   - Keep SKILL.md under 5000 words

2. **Reduce enabled skills**
   - Disable skills you're not actively using
   - If you have 20+ skills enabled, that's usually too many
   - Consider "skill packs" — related capabilities in one skill rather than 5 small skills

3. **Audit references/**
   - Each reference loaded on demand should be self-contained
   - No reference should itself inline a full API spec when a linked-further-down reference exists

## User complaints vs. root causes

Users report symptoms; skill authors fix root causes. Common mismatches:

| User says | Often actually means |
|---|---|
| "The skill is slow" | SKILL.md is too long |
| "The skill gives wrong answers" | Description too broad, wrong skill loading |
| "The skill asks too many questions" | Instructions don't cover the common case |
| "The skill crashed" | Usually MCP auth expired, not skill code |
| "The skill is confusing" | Description doesn't make scope clear |

## Escalation path

If troubleshooting is stuck after a few iterations:

1. **Compare with a known-good similar skill** — Anthropic's [public skills repo](https://github.com/anthropics/skills) has curated examples
2. **Ask `skill-creator` for a review** — "Review this skill and suggest improvements"
3. **Open a GitHub issue** at `anthropics/skills/issues` with skill name, error message, and reproduction steps
4. **Ask in the Claude Developers Discord** for community input

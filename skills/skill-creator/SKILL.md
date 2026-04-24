---
name: skill-creator
description: Guide users through creating custom skills for Claude Code — both command skills (invoked via /slash) and context skills (auto-loaded by tech stack). Use when the user asks to create a skill, build a skill, make a new slash command skill, or add a coding standards skill.
type: command
source: Inspired by https://github.com/AJBcoding/claude-skill-eval; structure aligned with Anthropic's "Complete Guide to Building Skills for Claude" (Jan 2026).
---

# Skill Creator

## Overview

A skill is a folder that teaches Claude how to handle a specific task or workflow. Skills live in `~/.claude/custom/skills/<name>/`, survive `claude-code-setup` upgrades, and are automatically discovered by Claude Code.

**Two types:**
- **Command skills** — invoked explicitly via `/skill-name` (e.g. `/deploy-staging`)
- **Context skills** — auto-loaded when the project's Tech Stack matches (e.g. `standards-python` loads for Python projects)

This skill walks the user through an 8-step interactive creation flow. Use the bundled references for depth on any individual step.

## Critical rules (always)

- `SKILL.md` — **exact filename**, case-sensitive. `skill.md`, `SKILL.MD`, etc. all fail.
- Name — **kebab-case only**. No `claude` or `anthropic` prefix (both reserved).
- Description — **under 1024 chars**, must include **both** what the skill does **and** when to use it. No XML angle brackets (`<` or `>`) — security restriction.
- **No `README.md`** inside the skill folder. Repo-level READMEs (for GitHub visitors) are fine.
- SKILL.md — keep **under ~5000 words**. Move depth into `references/`.

Full rules and frontmatter schema: `references/02-frontmatter.md`.

## Creation Flow (8 steps, interactive)

Use conversational interaction — ask one question at a time, wait for the answer before moving on.

### Step 1 — Concrete use cases

Ask:

> Give me 2–3 specific, concrete scenarios where you want this skill to kick in.
> Format: "I say X" → "Claude does Y".

The quality of the skill is capped by the quality of the use cases. Vague cases ("help with projects") produce unusable skills. Specific cases ("onboard a new PayFlow customer: create account → setup payment → activate subscription") produce skills that trigger reliably and behave consistently.

If the user gives only one scenario, push for at least two more — paraphrased versions of the same task, or related edge cases.

### Step 2 — Skill type

Map the use cases to a type:

- If the trigger is explicit ("deploy X", "generate report", "scaffold Y") → **command skill**
- If the skill should apply automatically when touching certain files, file extensions, or tech stacks → **context skill**

If ambiguous, present both options and let the user pick:

```
Command skill — invoked as /skill-name
   Example: /deploy-staging, /generate-report
   Pro: deterministic invocation
   Con: user must remember the command

Context skill — auto-loaded by tech stack or file extension
   Example: standards-python, api-conventions
   Pro: always applied, no user effort
   Con: consumes context tokens on every matching project
```

### Step 3 — Name + description

Propose a **kebab-case** name based on the use cases. The folder name, frontmatter `name`, and directory must all match.

Write the description in this structure:

> **[What it does]** + **[When to use it, with trigger phrases]** + *(optional)* **[Key capabilities]**

Good and bad examples, plus the full test ("would Claude know to pick this skill when the user says X?"): `references/03-writing-descriptions.md`.

### Step 4 — Pick a pattern

Most skills fit one of 5 patterns. Identify which fits before writing instructions.

| # | Pattern | When |
|---|---------|------|
| 1 | Sequential workflow orchestration | Multi-step process, steps in a specific order |
| 2 | Multi-MCP coordination | Workflow spans multiple MCP servers |
| 3 | Iterative refinement | Output quality improves through repeat passes |
| 4 | Context-aware tool selection | Same outcome, different tools depending on context |
| 5 | Domain-specific intelligence | Specialized expertise beyond tool access |

Full descriptions with ready-to-copy structures: `references/05-patterns.md`.

### Step 5 — Decide the folder structure

Most skills need **only `SKILL.md`**. Add folders only when justified.

```
<skill-name>/
├── SKILL.md              required
├── references/           optional — detailed docs loaded on demand
├── assets/               optional — templates the skill produces
└── scripts/              optional — executable code (Python, Bash, etc.)
```

- **`references/`** — use when SKILL.md would otherwise exceed 5000 words
- **`assets/`** — use when the skill produces outputs from templates (letters, reports, decks)
- **`scripts/`** — use when a step needs determinism (code is reliable; language interpretation isn't). Common: validation, parsing, file manipulation.

See `references/01-progressive-disclosure.md` for the full three-level model.

### Step 6 — Generate the content

Write `SKILL.md` using the pattern from Step 4. Apply the rules in `references/04-writing-instructions.md`:

- Lead with the decision flow, not prose
- Be specific and actionable — concrete commands/queries, not abstractions
- Structure with headers and bullets, not paragraphs
- Include error handling and worked examples
- Move depth to `references/` the moment SKILL.md threatens to bloat

If the user asked to provide instructions themselves, review their draft against these rules and suggest concrete edits.

### Step 7 — Test

Three checks before calling the skill done:

1. **Triggering** — does Claude load the skill when asked the expected questions? Paraphrase the question; also check that unrelated topics do NOT trigger.
2. **Functional** — does the skill produce correct outputs for the use cases from Step 1?
3. **Performance** — does the skill save tokens + tool calls vs. a no-skill baseline?

Full method and example test matrix: `references/06-testing.md`.

### Step 8 — Save and verify

Create the folder at `~/.claude/custom/skills/<name>/` and write the files.

Run through `references/08-checklist.md` before telling the user the skill is ready.

Show the invocation:

- **Command skill:** `/<name>`
- **Context skill:** "auto-loads when Tech Stack includes `<applies-to value>`"

## Troubleshooting (quick reference)

Full diagnosis: `references/07-troubleshooting.md`.

| Symptom | First suspect |
|---------|---------------|
| Skill never triggers | Description too vague — add trigger phrases ("Use when user says …") |
| Skill triggers on unrelated queries | Description too broad — add negative triggers ("Do NOT use for …") |
| Instructions not followed | SKILL.md too long or key points buried — tighten, add `## CRITICAL` headers |
| "Could not find SKILL.md" | Filename not exact `SKILL.md` (case-sensitive) |
| "Invalid frontmatter" | Missing `---` delimiters, unclosed quotes, or XML brackets in a field |

## Resources

**Internal (bundled, read on demand):**

- `references/01-progressive-disclosure.md` — 3-level system; when to use references/assets/scripts
- `references/02-frontmatter.md` — all YAML fields, security rules, reserved names
- `references/03-writing-descriptions.md` — trigger phrases, what+when structure, good/bad examples
- `references/04-writing-instructions.md` — specificity, structure, error handling, when to use scripts
- `references/05-patterns.md` — the 5 common patterns with full example structures
- `references/06-testing.md` — triggering / functional / performance testing methods
- `references/07-troubleshooting.md` — upload errors, trigger diagnosis, MCP issues, large-context issues
- `references/08-checklist.md` — pre-upload and post-upload checklists

**Asset templates (bundled, copy-then-modify):**

- `assets/skill-template.md` — minimal `SKILL.md` starter
- `assets/command-skill-example.md` — worked example of a command skill (sequential workflow)
- `assets/context-skill-example.md` — worked example of a context skill (coding standards)

**Official:**

- [Anthropic Skills documentation](https://docs.anthropic.com/en/docs/claude-code/skills)
- [The Complete Guide to Building Skills for Claude (PDF, ~33 pages)](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf)
- [Example skills repository](https://github.com/anthropics/skills)

## Output location

All skills created through this flow go to:

```
~/.claude/custom/skills/<skill-name>/
```

This location is separate from the base installation (`~/.claude/skills/`) and survives `claude-code-setup` upgrades.

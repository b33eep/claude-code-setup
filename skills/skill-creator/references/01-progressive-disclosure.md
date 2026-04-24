# Progressive Disclosure

Skills use a three-level loading system. Understanding it is the difference between skills that scale and skills that burn context.

## The three levels

| Level | Loaded when | Stored in | Budget |
|---|---|---|---|
| **Level 1 — Frontmatter** | Always, in Claude's system prompt | YAML at top of `SKILL.md` | `description` under 1024 chars |
| **Level 2 — SKILL.md body** | When Claude decides the skill is relevant | Body of `SKILL.md` | Under ~5000 words |
| **Level 3 — Linked files** | When Claude navigates to them explicitly | `references/`, `assets/`, `scripts/` | No hard limit (load what's needed) |

The goal: Level 1 tells Claude *whether* the skill applies, Level 2 tells Claude *how* to do the task, Level 3 supplies depth on demand.

## What goes where

### Level 1 — Frontmatter

Only what Claude needs to decide "is this skill relevant to the user's request?"

```yaml
---
name: customer-onboarding
description: End-to-end customer onboarding for PayFlow. Handles account creation, payment setup, and subscription activation. Use when the user says "onboard new customer", "set up subscription", or "create PayFlow account".
type: command
---
```

Write for the **trigger matcher**, not the human reader. Every word should help Claude decide to pick this skill over a similar one. See `03-writing-descriptions.md` for examples.

### Level 2 — SKILL.md body

The **decision flow** and **core rules**. If a user hits the skill and reads the body, they should know exactly what to do.

Good SKILL.md content:
- Ordered decision steps (Step 1 → Step 2 → …)
- Quick-reference tables (when to use which pattern)
- Anti-patterns (do NOT do X)
- Critical rules that must always apply

Content that does NOT belong in SKILL.md:
- Multi-page feature references
- Full API schemas
- Every possible error and its fix
- Ready-to-copy templates longer than ~30 lines

Move those to `references/` or `assets/` and link from SKILL.md. Keep body under ~5000 words. When in doubt: shorter.

### Level 3 — Linked files

Three folders, three purposes:

#### `references/`

Documentation Claude loads on demand. Each file is **self-contained** — Claude shouldn't need to read SKILL.md again to understand a reference.

Use for:
- Detailed API/command/syntax reference
- Error catalog with fixes
- Pattern deep-dives (the 5 patterns, expanded)
- Troubleshooting procedures

File naming: `NN-topic.md` (e.g. `01-api-reference.md`, `02-error-codes.md`). Numbering helps humans browse; Claude reads whichever matches the current need.

#### `assets/`

**Skeletons the user or skill copies and modifies** — templates, worked examples, fonts, icons, schemas. Anything Claude shouldn't generate from scratch when a stable starting point exists.

Use for:
- Report/letter/document templates
- Boilerplate structures (starter decks, repo scaffolds)
- Config files the skill writes with user-specific values
- **Worked examples** — full, usable reference implementations the user adapts (distinct from terse `references/*.md` docs)

Rule: if it's *copied and modified*, it's an asset. If it's *read and applied*, it's a reference.

#### `scripts/`

**Executable code** (Python, Bash, Node) the skill runs directly. Use when language interpretation is unreliable and determinism matters.

Classic use cases:
- Input validation (schema checks, format verification)
- File parsing (CSV, XML, binary formats)
- Generating derived data (compute metrics, build indexes)
- Anything involving precise math or multi-step transforms

**Why not just instructions?** Scripts are deterministic. Language interpretation isn't. If a validation step must produce the same result every time, script it. Anthropic's Office skills use scripts for this exact reason.

Example:

```
my-skill/
├── SKILL.md
├── scripts/
│   ├── validate_csv.py      # called from SKILL.md: `python scripts/validate_csv.py <file>`
│   └── normalize_names.sh
```

From SKILL.md:

```markdown
Before processing, run:

```bash
python scripts/validate_csv.py {input-file}
```

If validation fails, fix the input and re-run. Do not proceed on validation errors.
```

## When to split SKILL.md into references/

Move a section out of SKILL.md when **any one of these** is true:

- SKILL.md word count is approaching 5000
- A section is rarely needed (e.g. "advanced troubleshooting") — demoting it saves Level 2 tokens
- The section is self-contained (no tight cross-refs with the decision flow)
- The section is a catalog (reference tables, error lists, pattern library)

Keep in SKILL.md:

- The decision flow itself
- Critical rules that must always apply
- Anti-patterns
- Quick-reference tables that support the decision flow

## Measuring the win

Progressive disclosure succeeds when:

- A user who never touches the skill pays only Level 1 tokens (just the description)
- A user who invokes the skill loads Level 1 + Level 2 — still compact
- A user who hits a rare edge case loads Level 3 only for the relevant reference

Contrast with a single bloated SKILL.md: every user pays for every rare edge case, every time.

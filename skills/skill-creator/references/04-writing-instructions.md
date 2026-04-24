# Writing Instructions

The body of `SKILL.md` tells Claude how to do the task. This reference covers what goes there, how to structure it, and when to reach for scripts instead of prose.

## Be specific and actionable

### Good

```markdown
Before writing queries, consult `references/api-patterns.md` for:
- Rate limiting guidance
- Pagination patterns
- Error codes and handling

Run `python scripts/validate.py --input {filename}` to check data format.

If validation fails, common issues include:
- Missing required fields (add them to the CSV)
- Invalid date formats (use YYYY-MM-DD)
```

### Bad

```markdown
Validate the data before proceeding.
```

What data? How? What does "validate" mean? Claude has to guess, and guesses differ across conversations — meaning inconsistent behavior.

**Rule:** every instruction should specify **what** to do, **how** to do it (command/query/path), and **what success looks like**.

## Structure for scannability

Claude scans SKILL.md like a decision tree. Structure accordingly:

- **Headers** mark decision points (`## Step 1`, `## When X`, `## If Y`)
- **Tables** compress enumerations (intent → feature, error → fix)
- **Bullets** list alternatives or sequential steps
- **Paragraphs** are for rationale, not instructions

If a section is three paragraphs of prose, it's probably hiding a decision that should be a table or a numbered list.

## Lead with the decision flow

The first thing Claude reads after Overview should be the **decision flow**:

```markdown
## Decision Flow

### 1. Is this a new deck or an existing one?

**New deck** → Step 2.
**Existing deck** → Read slides.md first; never rewrite. Skip to Editing Workflow.

### 2. Pick the template that fits

| User signal | Template |
|---|---|
| "simple deck" | `assets/starter-deck.md` |
| "conference talk" | `assets/conference-deck.md` |
```

The decision flow is the skeleton. Everything else (quality checklist, troubleshooting, resources) hangs off it.

## Put critical rules at the top

If a rule must always apply, put it **above** the detailed flow, labeled clearly:

```markdown
## Critical rules (always)

- Never `rm -rf` without explicit user confirmation
- All commits include a scope: `feat(scope): ...`
- No emojis in committed code or docs
```

Why at the top: Claude reads top-down. Rules near the bottom are more easily forgotten when the body is long.

## Include error handling

Every skill should anticipate the common failure modes and tell Claude how to recover:

```markdown
## Troubleshooting

### "Connection refused"

1. Check that the MCP server is connected (Settings → Extensions)
2. Verify API key is current
3. If still failing, reconnect via Settings → [Service] → Reconnect

### "Invalid input format"

Common causes:
- Timestamp in wrong format (need ISO 8601)
- Missing required field `customer_id`

Fix the input and re-run. Do not silently skip validation.
```

Error handling in SKILL.md for common cases. Move rare/complex errors to `references/07-troubleshooting.md`.

## Include worked examples

Abstract instructions ("use the API") are weaker than concrete examples:

```markdown
### Example 1: Simple customer onboarding

User says: "Set up customer Alice <alice@example.com> on the Pro plan"

Actions:
1. Call `create_customer` with `{name: "Alice", email: "alice@example.com"}`
2. Fetch plan ID: `list_plans` → find "Pro" → `plan_123`
3. Call `create_subscription` with `{customer_id: from_step_1, plan_id: plan_123}`

Result: Customer Alice on Pro plan, subscription active immediately.
```

One worked example per major use case. More if the use cases diverge significantly.

## Be explicit about "don't"

Claude follows instructions, but also "reasons about" the task. If a reasonable-seeming action would be wrong, say so:

```markdown
## Do NOT

- Modify `main` branch directly — always create a feature branch
- Amend commits that have been pushed — use a new commit instead
- Run `git push --force` without explicit user confirmation
- Commit files larger than 5 MB — use Git LFS
- Commit `.env` or any file with secrets
```

Explicit negatives stop Claude from taking "reasonable but wrong" shortcuts.

## When to reach for scripts

Language instructions are probabilistic. For **deterministic** tasks, write a script:

| Task | Prose or script? |
|---|---|
| "Validate a CSV has columns A, B, C" | Script — prose validation is unreliable |
| "Compute the 95th percentile of a list" | Script — math should be deterministic |
| "Parse an XML file and extract all `<node>` tags" | Script |
| "Summarize what a function does" | Prose — language is the right tool |
| "Decide whether to use React or Vue for this project" | Prose — reasoning is the point |
| "Run existing tests and report failures" | Script — `pytest` knows how |

From SKILL.md, call scripts by path:

```markdown
Before processing, validate the input file:

```bash
python scripts/validate_input.py {filename}
```

Expected output: `OK` (exit 0) or a list of errors (exit non-zero).

If validation fails, show the user the errors and do not proceed.
```

Scripts live in `scripts/`, documented by comments. They should:

- Accept arguments rather than hardcoding values
- Exit with non-zero on error
- Emit clear, machine-parseable output (JSON or line-delimited)
- Be idempotent when possible

Example `scripts/validate_csv.py`:

```python
#!/usr/bin/env python3
"""Validate a CSV has required columns."""
import csv
import sys

REQUIRED = {"customer_id", "email", "signup_date"}

def main(path: str) -> int:
    with open(path) as f:
        headers = set(next(csv.reader(f)))
    missing = REQUIRED - headers
    if missing:
        print(f"ERROR: missing columns: {sorted(missing)}", file=sys.stderr)
        return 1
    print("OK")
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
```

## Reference bundled resources clearly

When SKILL.md points to another file, be explicit:

```markdown
# Good
Before writing queries, consult `references/api-patterns.md` for rate limiting and pagination.

# Bad
See the reference for more info.
```

The path tells Claude exactly where to navigate.

## Length budget

Target under **5000 words** for SKILL.md. That's roughly:

- 8 typical headers with 400–600 words each, or
- 3 long sections (decision flow, rules, troubleshooting) + several short ones

Word-count tips:

- Move completed / rare troubleshooting to `references/07-troubleshooting.md`
- Move API/syntax reference to `references/0X-<topic>.md`
- Inline only the core decision flow + critical rules + quality checklist

## Anti-patterns

### Inlining a 5000-line API reference

```markdown
# Bad
## Full API Reference

### Endpoint: POST /customers
Parameters:
- name (string, required): ...
[200 more lines]
```

Move to `references/api-reference.md`. SKILL.md references it:

```markdown
For the full API reference, see `references/api-reference.md`.

Common calls:
- Create customer → `POST /customers`
- Get customer → `GET /customers/{id}`
```

### Explaining Claude's internals

```markdown
# Bad
Claude uses progressive disclosure to load this skill efficiently...
```

Claude doesn't need this explained at runtime. It's meta-talk that consumes tokens without changing behavior.

### Vague encouragements

```markdown
# Bad
Try your best to do this correctly.
Think carefully about the problem.
Be sure to validate thoroughly.
```

These phrases feel instructive but say nothing concrete. Replace with specific checks: "Verify X, confirm Y, check Z."

### Sentimental language

```markdown
# Bad
This is a really important skill! Make sure users have a great experience.
```

Not actionable. Cut.

## Structural checklist

Before calling SKILL.md done:

- [ ] Decision flow is the first major section after Overview
- [ ] Critical rules are stated once, clearly, at the top
- [ ] Every instruction is specific (what + how + success criteria)
- [ ] Tables/bullets for enumerations, not prose
- [ ] Error handling covers the common 2–3 failure modes
- [ ] 1+ worked example per major use case
- [ ] Anti-patterns section lists what NOT to do
- [ ] Resources section lists references/assets/scripts with one-line purpose
- [ ] Word count under 5000

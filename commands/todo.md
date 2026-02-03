# Todo: Quick Capture for Backlog

Quick capture tool for the Future table. For structured planning, use `/design`.

```
/todo = CAPTURE (quick backlog entry)
/design = PLAN (structured design with Record)
```

## Usage

```
/todo                          # List all todos
/todo Fix typo in README       # Add simple todo
/todo Add notification system  # Complex → hint to use /design
```

## Tasks

### Prerequisites

- If no project CLAUDE.md found: Tell user to run `/init-project` first
- If no `### Future` section exists: Create it with standard header:
  ```markdown
  ### Future

  | Todo | Priority | Problem | Solution |
  |------|----------|---------|----------|
  ```

### Without arguments: List todos

1. Read project CLAUDE.md
2. Find the `### Future` section and its table
3. Display current todos in table format
4. If no todos: "No open todos."

### With arguments: Add todo

1. Read project CLAUDE.md
2. Find the `### Future` section and its table
3. **Check for duplicates**: If similar todo exists, ask whether to update or add new
4. **Assess complexity**:

   **Simple** (just add to table):
   - Bug fix, typo, small change
   - Config tweak
   - Single file change
   - Clear solution, no design needed

   **Complex** (hint to use /design):
   - Feature with multiple parts
   - Needs spec or design decisions
   - Architecture decision
   - Multiple sessions likely
   - Unsure how to implement

5. **If simple**: Add row to Future table
   ```markdown
   | Fix login timeout | Low | Login fails after 30s | Increase timeout |
   ```

6. **If complex**: Do NOT create a Record. Instead:
   ```
   This looks like it needs proper design (multiple parts, architecture decision).

   Consider using: /design "Add notification system"

   Or add as simple reminder anyway? [Yes / No]
   ```
   - If user says Yes: Add to Future table as reminder
   - If user says No: Suggest running /design

7. Confirm what was added

## Complexity Indicators

| Indicator | Simple | → Use /design |
|-----------|--------|---------------|
| One-liner fix | ✓ | |
| Single file change | ✓ | |
| Clear solution | ✓ | |
| Feature with multiple parts | | ✓ |
| Needs design decisions | | ✓ |
| Architecture decision | | ✓ |
| Multiple sessions likely | | ✓ |
| Unsure how to implement | | ✓ |

## Priority Guidelines

| Priority | When |
|----------|------|
| High | Blocking other work, urgent bug |
| Medium | Next planned feature, important improvement |
| Low | Nice to have, future idea |

## Lifecycle

`/todo` only manages the **Future** table:
- Add items as quick reminders
- When work begins: Move to Current Status table manually
- `/wrapup` updates Current Status at session end

## /todo vs /design

| Aspect | /todo | /design |
|--------|-------|---------|
| Purpose | Quick capture | Structured planning |
| Output | Future table row | Record with Stories |
| Use when | "Remember this for later" | "Plan how to build this" |
| Complexity | Simple items | Complex features |
| Design decisions | No | Yes (Options → Solution) |

## Examples

```
User: /todo Fix typo in README header
→ Added to Future: | Fix typo in README | Low | Typo in heading | Fix spelling |

User: /todo Add OAuth2 authentication
→ This looks like it needs proper design (architecture decision, multiple parts).

  Consider using: /design "Add OAuth2 authentication"

  Or add as simple reminder anyway? [Yes / No]

User: No
→ Run: /design "Add OAuth2 authentication"

User: /todo
→ Open todos:
  | Todo | Priority | Problem | Solution |
  |------|----------|---------|----------|
  | Fix typo in README | Low | Typo in heading | Fix spelling |
```

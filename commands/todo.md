# Todo: Manage Project Todos

List or add todos in the project CLAUDE.md Future table. Keeps CLAUDE.md lean - complex todos get a Record.

## Tasks

### Prerequisites

- If no project CLAUDE.md found: Tell the user to run `/init-project` first
- If no `### Future` section or table exists: Create it with the standard header:
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
3. **Check for duplicates**: If a similar todo already exists in the Future table, inform the user and ask whether to update the existing entry or add a new one
4. Assess the todo:

   **Simple** (bug fix, small change, config tweak):
   - Append row to Future table
   - Fill in Priority, Problem, Solution inline
   - Example: `| Fix login timeout | Low | Login fails after 30s | Increase timeout |`

   **Complex** (feature, architecture, multi-session, needs spec/plan):
   - Create a Record in `docs/records/` with problem, spec, and plan
   - Append row to Future table with link to Record
   - Example: `| Add caching layer | Medium | API too slow | [Record 019](docs/records/019-caching.md) |`

5. **If unsure** whether simple or complex: Ask the user
6. Confirm what was added

## Lifecycle

`/todo` only manages the **Future** table. When work begins on a todo:
- Move the row from Future to the **Current Status** table with status "In Progress"
- This transition happens naturally during implementation, not via `/todo`
- `/wrapup` updates the Current Status table at session end

## Decision: Simple vs Complex

| Indicator | → Simple | → Complex |
|-----------|----------|-----------|
| One-liner fix | x | |
| Needs spec or design | | x |
| Multiple sessions | | x |
| Architecture decision | | x |
| Single file change | x | |
| Would write >5 lines in CLAUDE.md | | x |

## Record Format (for complex todos)

Scan `docs/records/` for the highest existing number and increment. Follow existing naming:

```
docs/records/{NNN}-{short-title}.md
```

Content should include:
- Problem statement
- Proposed solution / spec
- Implementation plan (if applicable)

## Priority Guidelines

| Priority | When |
|----------|------|
| High | Blocking other work, urgent bug |
| Medium | Next planned feature, important improvement |
| Low | Nice to have, future idea |

## Examples

```
User: /todo Fix typo in README header
→ Appends: | Fix typo in README header | Low | Typo in main heading | Fix spelling |

User: /todo Add OAuth2 authentication
→ Creates Record 019 with spec
→ Appends: | Add OAuth2 authentication | Medium | No auth system | [Record 019](docs/records/019-oauth2-auth.md) |

User: /todo
→ Lists:
  Open todos:
  | Todo | Priority | Problem | Solution |
  |------|----------|---------|----------|
  | /do-review command | Low | Unclear when to trigger code review | Create command + refine global prompt |
```

# Global Claude Code Configuration

## Conventions

- Commits in English
- No emojis in code/docs unless explicitly requested

---

## Workflow: Session & Context Management

### Session Start (after /clear or new chat)

**Claude MUST on every session start:**

1. **Read `CLAUDE.md`** (automatically loaded)

2. **Run `/catchup`** → Read changed files

3. **If no CLAUDE.md exists** → Run `/init-project` to set up the project

### Context Rules

| Rule | Description |
|------|-------------|
| **No /compact** | Never use. Auto-compaction is error-prone. |
| **Document & Clear** | At context limit: Run `/clear-session`, then `/clear` |
| **External Memory** | CLAUDE.md + ADR are the "memory" - versioned, readable, persistent |

### End Session

```
/clear-session  → Documents status in CLAUDE.md
/clear          → Clear context
```

### After /clear

```
1. CLAUDE.md is automatically loaded
2. /catchup for changed files
3. Continue where you left off
```

---

## Development Flow

```
┌─────────────────────────────────────────────────────────┐
│  1. SPECIFY                                             │
│     - Define user story / task in CLAUDE.md             │
│     - Set acceptance criteria                           │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  2. IMPLEMENT                                           │
│     - Write code                                        │
│     - Write tests                                       │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  3. CODE REVIEW                                         │
│     - Agent: code-review-ai:architect-review            │
│     - Incorporate feedback                              │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
                    Back to 1.
                         or
              /clear-session → /clear
```

> **Note:** `/clear-session` handles updating CLAUDE.md and committing changes.

---

## File Structure: What Goes Where?

### Global (~/.claude/CLAUDE.md)

- Coding standards (selected during install)
- General conventions
- This workflow

### Project (project/CLAUDE.md)

- Project overview
- Tech stack
- **Current status** (status table)
- User stories with status
- Architecture decisions (brief, with ADR link)
- Development commands
- Next step

### ADR (docs/adr/)

- One file per decision
- Format: `{NNN}-{short-title}.md`
- Context, decision, consequences

---

## MCP Servers

Available MCP servers for extended functionality (configured during install):

| Server | Description |
|--------|-------------|
| `pdf-reader` | Read and analyze PDF documents |
| `brave-search` | Web search via Brave Search API |
| `google-search` | Web search via Google Custom Search API |

> **Note:** Run `./install.sh --list` to see installed servers.

---

## Skills

Available skills for specialized tasks (`~/.claude/skills/`):

| Skill | Description |
|-------|-------------|
| `create-slidev-presentation` | Create/edit Slidev presentations |

> **Note:** Run `./install.sh --list` to see installed skills.

---

## Template: Project CLAUDE.md

> Claude creates this template automatically and adapts it to the specific project.

```markdown
# {Project Name}

## About

{1-2 sentences description}

## Tech Stack

{Language, framework, key dependencies}

---

## Current Status

| Story | Status | Tests | Notes |
|-------|--------|-------|-------|
| US-1 | {Status} | {N} | {Brief info} |

**Legend:** Open | In Progress | Done

**Next Step:** {What's next}

---

## Architecture Decisions

| Decision | Choice | ADR |
|----------|--------|-----|
| {What} | {Decision} | [ADR-001](docs/adr/001-xxx.md) |

---

## User Stories

### US-1: {Title}
- [ ] Task 1
- [ ] Task 2

---

## Development

{Build, test, run commands}
```

---

## Coding Standards

### Core Principles

1. **Simplicity**: Simple, understandable code
2. **Readability**: Readability over cleverness
3. **Maintainability**: Code that's easy to maintain
4. **Testability**: Code that's easy to test
5. **DRY**: Don't Repeat Yourself - but don't overdo it

### General Rules

- **Early Returns**: Use early returns to avoid nesting
- **Descriptive Names**: Meaningful names for variables and functions
- **Minimal Changes**: Only change relevant code parts
- **No Over-Engineering**: No unnecessary complexity
- **Minimal Comments**: Code should be self-explanatory. No redundant comments!

{{STANDARDS_MODULES}}

---

## Git Commit Messages

Format: `<type>(<scope>): <description>`

Types:
- `feat`: New features
- `fix`: Bug fixes
- `docs`: Documentation
- `refactor`: Code refactoring
- `test`: Add/modify tests
- `chore`: Maintenance tasks

Examples:
```
feat(auth): add OAuth2 login support
fix(api): handle null response from user endpoint
refactor(user-service): extract validation logic
```

**No Co-Authored-By** - Create commits without Co-Authored-By line.

---

## Code Review Checklist

**Functionality:**
- [ ] Does the code work as expected?
- [ ] Are all edge cases handled?
- [ ] Is there sufficient error handling?

**Code Quality:**
- [ ] Are names descriptive?
- [ ] Is the code testable and tested?
- [ ] No hardcoded values (secrets, URLs)?
- [ ] No console.log/print statements?
- [ ] Typing complete?

**Architecture & Patterns:**
- [ ] No duplicated code across classes? → Extract Base Class
- [ ] No if/elif chains for types/variants? → Strategy Pattern
- [ ] No N queries in loops? → Batch Query
- [ ] No repeated transformation logic? → Helper Function
- [ ] DTOs immutable where appropriate? → `frozen=True`

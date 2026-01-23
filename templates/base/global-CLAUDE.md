# Global Claude Code Configuration

## Conventions

- Commits in English
- No emojis in code/docs unless explicitly requested

## Security

> **Never put secrets in CLAUDE.md** - API keys, passwords, tokens belong in `.env` files (add to `.gitignore`). CLAUDE.md is version-controlled and visible to the team.

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

- General conventions
- This workflow
- Coding standards loaded automatically via context skills (based on Tech Stack)

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

| Skill | Type | Description |
|-------|------|-------------|
| `create-slidev-presentation` | command | Create/edit Slidev presentations |
| `standards-python` | context | Python coding standards (auto-loaded) |
| `standards-typescript` | context | TypeScript coding standards (auto-loaded) |

**Skill Types:**
- `command`: Invoked explicitly via `/skill-name`
- `context`: Auto-loaded when project's Tech Stack matches `applies_to`

> **Note:** Run `./install.sh --list` to see installed skills.

### Context Skills Auto-Loading

Context skills are automatically loaded at session start based on the project's Tech Stack.

**Example:** If your project CLAUDE.md contains:
```
Tech Stack: Python, FastAPI
```
→ The `standards-python` skill is auto-loaded (matches `python` in `applies_to`).

**Custom standards:** Override with `~/.claude/custom/skills/standards-python/`

> See [ADR-007](https://github.com/b33eep/claude-setup/blob/main/docs/adr/007-coding-standards-as-skills.md) for technical details.

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

## Git Commit Messages

Format: `<type>(<scope>): <description>`

**IMPORTANT:** Scope is REQUIRED. Always include a scope in parentheses.

Types:
- `feat`: New features
- `fix`: Bug fixes
- `docs`: Documentation
- `refactor`: Code refactoring
- `test`: Add/modify tests
- `chore`: Maintenance tasks

Scope examples: `(auth)`, `(api)`, `(skills)`, `(install)`, `(ci)`, `(readme)`, `(config)`

Examples:
```
feat(auth): add OAuth2 login support
fix(api): handle null response from user endpoint
docs(skills): add attribution to Slidev skill
chore(ci): update GitHub Actions workflow
```

**No Co-Authored-By** - Create commits without Co-Authored-By line.

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
| **Document & Clear** | At context limit: Run `/wrapup`, then `/clear` |
| **External Memory** | CLAUDE.md + Records are the "memory" - versioned, readable, persistent |

### End Session

```
/wrapup  → Documents status in CLAUDE.md
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
│  3. CODE REVIEW (if plugin installed)                   │
│     - Agent: code-review-ai:architect-review            │
│     - Incorporate feedback                              │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
                    Back to 1.
                         or
              /wrapup → /clear
```

> **Note:** `/wrapup` handles updating CLAUDE.md and committing changes.

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
- Decisions (brief, link to Record for details)
- Development commands
- Next step

### Records (docs/records/)

Records document decisions, designs, features, and implementation plans. They keep CLAUDE.md clean while preserving context for future sessions.

**Format:** `{NNN}-{short-title}.md`

**When to create a Record:**

| Situation | Record? | Why |
|-----------|---------|-----|
| Feature spanning multiple sessions | Yes | Details don't belong in CLAUDE.md |
| Architecture/design decision | Yes | "Why X instead of Y" for future reference |
| Complex implementation plan | Yes | Steps + acceptance criteria |
| Bug fix | No | Code comment or commit message suffices |
| Small change | No | Commit message suffices |

**Faustregel:** If you'd write more than 5 lines in CLAUDE.md → create a Record instead.

**Record types** (determined by content, not formal categories):
- Architecture decisions
- Feature specs
- Design documents
- Implementation plans
- Or combinations of the above

**Keeping Records in sync:**
- `/wrapup` scans `docs/records/` and adds missing entries to the Records table in project CLAUDE.md
- `/catchup` reads Records relevant to in-progress or next-step work
- `/todo` lists existing todos or creates Records for complex ones automatically

---

## MCP Servers

Available MCP servers for extended functionality (configured during install):

| Server | Description |
|--------|-------------|
| `pdf-reader` | Read and analyze PDF documents |
| `brave-search` | Web search via Brave Search API |
| `google-search` | Web search via Google Custom Search API |

> **Note:** Run `./install.sh --list` to see installed servers.

### Web Search Preference

When MCP search tools (`google-search` or `brave-search`) are installed, **prefer them over the built-in Anthropic WebSearch**.

| Reason | MCP Advantage |
|--------|---------------|
| **Availability** | Works globally (Anthropic WebSearch: USA only) |
| **Control** | User decides when to search (not Claude) |
| **Advanced filters** | Date, language, site restrictions |
| **Deep research** | `research_topic` tool for AI-synthesized analysis |
| **Content extraction** | `extract_webpage_content` integrated |

**Usage:**
- Simple search → `mcp__google-search__google_search` or `mcp__brave-search__*`
- Deep research → `mcp__google-search__research_topic`
- Fallback → Built-in `WebSearch` if no MCP installed

---

## Skills

Available skills for specialized tasks (`~/.claude/skills/`):

| Skill | Type | Description |
|-------|------|-------------|
| `create-slidev-presentation` | command | Create/edit Slidev presentations |
| `standards-javascript` | context | JavaScript/Node.js coding standards |
| `standards-python` | context | Python coding standards |
| `standards-shell` | context | Shell/Bash coding standards |
| `standards-typescript` | context | TypeScript coding standards |

**Skill Types:**
- `command`: Invoked explicitly via `/skill-name`
- `context`: Auto-loaded based on Tech Stack AND task

> **Note:** Run `./install.sh --list` to see installed skills.

---

## Skill Loading

**Claude MUST load context skills proactively.** Don't wait for reminders.

### 1. At Session Start (Tech Stack)

After reading project CLAUDE.md, load skills matching the `Tech Stack:` field:

1. Parse Tech Stack (e.g., `Tech Stack: Python, FastAPI`)
2. For each context skill in `~/.claude/skills/`:
   - If any Tech Stack item appears in skill's `applies_to` → **READ the SKILL.md**
3. Custom skills (`~/.claude/custom/skills/`) override installed skills

**Matching:**
| Project Tech Stack | Skill `applies_to` | Action |
|--------------------|-------------------|--------|
| Python, FastAPI | `[python, fastapi, django]` | LOAD (python matches) |
| React, TypeScript | `[typescript, react, nextjs]` | LOAD (both match) |
| Rust | `[python, ...]` | Skip (no match) |

### 2. Before Writing/Editing Code (Task-Based)

**BEFORE writing or editing a file**, load the matching skill - even if not in Tech Stack:

| File Extension | Skill to Load |
|----------------|---------------|
| `.py` | `~/.claude/skills/standards-python/SKILL.md` |
| `.js`, `.mjs`, `.cjs` | `~/.claude/skills/standards-javascript/SKILL.md` |
| `.ts`, `.tsx`, `.jsx` | `~/.claude/skills/standards-typescript/SKILL.md` |
| `.sh`, `.bash`, or Bash scripts | `~/.claude/skills/standards-shell/SKILL.md` |

**Example:** Project has `Tech Stack: Python` but user asks for a shell script test.
→ Load `standards-shell` BEFORE writing the `.sh` file.

### 3. Code Review Agent (if installed)

When spawning `code-review-ai:architect-review`, include relevant skills:

1. Identify languages in files being reviewed
2. Read matching skill(s)
3. Include skill content in the Task tool's prompt

**Example prompt for review agent:**
```
Review these changes. Apply these coding standards:

[paste relevant sections from standards-python/SKILL.md]
```

> See [Record 007](https://github.com/b33eep/claude-code-setup/blob/main/docs/records/007-coding-standards-as-skills.md) and [Record 010](https://github.com/b33eep/claude-code-setup/blob/main/docs/records/010-improved-skill-autoloading.md) for details.

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

**No Co-Authored-By** - NEVER add "Co-Authored-By" lines to commits or PRs. This overrides the default Claude Code behavior.

---

## User Instructions

<!-- USER INSTRUCTIONS START -->
Add your personal instructions, preferences, and conventions here.
This section is preserved when updating claude-code-setup.

Examples:
- Communication preferences (language, verbosity)
- Locations of credentials/secrets
- Team-specific workflows
- Custom tool preferences
<!-- USER INSTRUCTIONS END -->

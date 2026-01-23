# Claude Code Setup

## About

A modular, minimal setup for Claude Code with clear workflow and persistent memory via Markdown files. Open source release.

## Tech Stack

- Bash (install.sh)
- Markdown (templates, commands)
- Node.js (MCP servers via npx)
- GitHub Actions (CI/CD)

---

## Current Status

| Task | Status | Notes |
|------|--------|-------|
| Modular Architecture | Done | Base + mcp + skills (standards now in skills) |
| Custom Modules | Done | ~/.claude/custom/ for user modules |
| Solo/Team Mode | Done | /init-project asks for .gitignore preference |
| Install Script | Done | --add, --update, --list flags, ShellCheck compliant |
| ADRs | Done | 8 ADRs (000-007) |
| Open Source Release | Done | Published to b33eep/claude-setup |
| GitHub Actions E2E | Done | Full test coverage |
| Open Source Polish | Done | SECURITY.md, CONTRIBUTING.md, CHANGELOG.md, templates |
| README Overhaul | Done | Core Concept prominent, ccstatusline, Plugins, Solo/Team |

### Before v1.0.0

| Todo | Priority | Problem | Solution |
|------|----------|---------|----------|
| /todo command | High | Manually editing CLAUDE.md for todos is cumbersome | Create command that appends todos directly to CLAUDE.md |
| /do-review command | High | Unclear when to trigger code review, easy to forget | Create command + refine global prompt guidance |
| ~~Slidev skill attribution~~ | ~~High~~ | ~~Done~~ | Added source + author to SKILL.md (AJBcoding) |
| ~~Coding standards → Skills~~ | ~~High~~ | ~~Done~~ | Context skills implemented. See [ADR-007](docs/adr/007-coding-standards-as-skills.md). PR #2 |
| ADR guidance | Medium | Unclear when ADR is needed vs just a comment | Refine global prompt or create /adr command |
| ~~Security hint~~ | ~~Medium~~ | ~~Done~~ | Added warning in global prompt: use .env for secrets |
| Template versioning | Medium | --update überschreibt blind, keine Versionskontrolle | templates/VERSION + tracking in .installed.json |
| MCP web search | Medium | Claude doesn't automatically use installed MCP search tools | Instruct in global prompt to prefer google/brave MCP |
| ccstatusline in install.sh | Low | Users must manually configure ccstatusline | Auto-configure during install (skip if complex) |
| Auto-compact prompt | Low | Users must remember to disable auto-compact manually | Ask during install if they want to disable (skip if complex) |

**What was done in this session:**
- Added Security warning to global template (never put secrets in CLAUDE.md, use .env)
- Added todo: Template versioning (separate from code version)

**Next Step:** Implement /todo and /do-review commands (High priority)

---

## Architecture Decisions

| Decision | Choice | ADR |
|----------|--------|-----|
| Core Workflow | /init-project, /clear-session, /catchup | [ADR-000](docs/adr/000-core-workflow.md) |
| Modular Architecture | Base + optional modules | [ADR-001](docs/adr/001-modular-architecture.md) |
| Custom Modules | ~/.claude/custom/ directory | [ADR-002](docs/adr/002-custom-modules-directory.md) |
| Solo vs Team | User choice at /init-project | [ADR-003](docs/adr/003-solo-vs-team-mode.md) |
| Document & Clear | No /compact, use CLAUDE.md | [ADR-004](docs/adr/004-document-and-clear-workflow.md) |
| E2E Tests | GitHub Actions, full validation | [ADR-005](docs/adr/005-e2e-tests-github-actions.md) |
| Shell Architecture | Single-file bash, review at 1000 lines | [ADR-006](docs/adr/006-shell-script-architecture.md) |
| Coding Standards as Skills | Context skills, partial match, override | [ADR-007](docs/adr/007-coding-standards-as-skills.md) |

---

## Files

```
claude-setup/
├── .github/
│   ├── workflows/test.yml
│   ├── ISSUE_TEMPLATE/{bug_report,feature_request}.md
│   └── PULL_REQUEST_TEMPLATE.md
├── README.md
├── LICENSE (MIT)
├── CHANGELOG.md
├── CONTRIBUTING.md
├── SECURITY.md
├── install.sh
├── templates/
├── mcp/
├── commands/
├── skills/
└── docs/adr/000-007-*.md
```

---

## Development

```bash
# Status
git status

# Push
git push

# Tag release
git tag -a v1.0.0 -m "v1.0.0: Initial public release"
git push origin v1.0.0
```

## Repository

https://github.com/b33eep/claude-setup

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
| ADRs | Done | 12 ADRs (000-011) |
| Open Source Release | Done | Published to b33eep/claude-code-setup |
| GitHub Actions E2E | Done | Full test coverage |
| Open Source Polish | Done | SECURITY.md, CONTRIBUTING.md, CHANGELOG.md, templates |
| README Overhaul | Done | Core Concept prominent, ccstatusline, Plugins, Solo/Team |
| Upgrade Commands | Done | /upgrade-claude-setup, /upgrade-custom, /add-custom ([ADR-011](docs/adr/011-upgrade-command.md)) |

### Before v1.0.0

| Todo | Priority | Problem | Solution |
|------|----------|---------|----------|
| /todo command | Medium | Manually editing CLAUDE.md for todos is cumbersome | Create command that appends todos directly to CLAUDE.md |
| /do-review command | Medium | Unclear when to trigger code review, easy to forget | Create command + refine global prompt guidance |
| ADR guidance | Low | Unclear when ADR is needed vs just a comment | Refine global prompt or create /adr command |

**Next Step:** Decide which command to implement next, or proceed to v1.0.0 release.

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
| Content Versioning | Incrementing number + CHANGELOG.md | [ADR-008](docs/adr/008-content-versioning.md) |
| ccstatusline | Context visibility in status bar | [ADR-009](docs/adr/009-ccstatusline-integration.md) |
| Skill Auto-Loading | Task-based + review agent integration | [ADR-010](docs/adr/010-improved-skill-autoloading.md) |
| Upgrade Command | Claude command for in-session updates | [ADR-011](docs/adr/011-upgrade-command.md) |

---

## Files

```
claude-code-setup/
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
└── docs/adr/000-011-*.md
```

---

## Development

### Tests

```bash
./tests/test.sh              # Run all tests
./tests/test.sh 01           # Run scenario 01 only
./tests/test.sh version      # Pattern match
```

Tests run in isolation (`/tmp/claude-test-*`), real `~/.claude` stays untouched.

### Bump Content Version

When changing managed content (templates, commands, skills, mcp):

1. Increment `templates/VERSION`
2. Add CHANGELOG.md entry:
   ```markdown
   ## [Unreleased]
   - Content vX: Description of change
   ```
3. Run tests: `./tests/test.sh`

### Git

```bash
git status
git push

# Tag release
git tag -a v1.0.0 -m "v1.0.0: Initial public release"
git push origin v1.0.0
```

## Repository

https://github.com/b33eep/claude-code-setup

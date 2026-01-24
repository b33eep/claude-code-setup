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
| Records | Done | 12 Records (000-011) |
| Open Source Release | Done | Published to b33eep/claude-code-setup |
| GitHub Actions E2E | Done | Full test coverage |
| Open Source Polish | Done | SECURITY.md, CONTRIBUTING.md, CHANGELOG.md, templates |
| README Overhaul | Done | Core Concept prominent, ccstatusline, Plugins, Solo/Team |
| Upgrade Commands | Done | /upgrade-claude-setup, /upgrade-custom, /add-custom ([Record 011](docs/records/011-upgrade-command.md)) |

### Before v1.0.0

| Todo | Priority | Problem | Solution |
|------|----------|---------|----------|
| /todo command | Medium | Manually editing CLAUDE.md for todos is cumbersome | Create command that appends todos directly to CLAUDE.md |
| /do-review command | Medium | Unclear when to trigger code review, easy to forget | Create command + refine global prompt guidance |
| ~~Records guidance~~ | ~~Low~~ | ~~Unclear when Record is needed vs just a comment~~ | Done - guidance added to global prompt |

**Next Step:** Decide which command to implement next, or proceed to v1.0.0 release.

---

## Records

| Decision | Choice | Record |
|----------|--------|--------|
| Core Workflow | /init-project, /clear-session, /catchup | [000](docs/records/000-core-workflow.md) |
| Modular Architecture | Base + optional modules | [001](docs/records/001-modular-architecture.md) |
| Custom Modules | ~/.claude/custom/ directory | [002](docs/records/002-custom-modules-directory.md) |
| Solo vs Team | User choice at /init-project | [003](docs/records/003-solo-vs-team-mode.md) |
| Document & Clear | No /compact, use CLAUDE.md | [004](docs/records/004-document-and-clear-workflow.md) |
| E2E Tests | GitHub Actions, full validation | [005](docs/records/005-e2e-tests-github-actions.md) |
| Shell Architecture | Single-file bash, review at 1000 lines | [006](docs/records/006-shell-script-architecture.md) |
| Coding Standards as Skills | Context skills, partial match, override | [007](docs/records/007-coding-standards-as-skills.md) |
| Content Versioning | Incrementing number + CHANGELOG.md | [008](docs/records/008-content-versioning.md) |
| ccstatusline | Context visibility in status bar | [009](docs/records/009-ccstatusline-integration.md) |
| Skill Auto-Loading | Task-based + review agent integration | [010](docs/records/010-improved-skill-autoloading.md) |
| Upgrade Command | Claude command for in-session updates | [011](docs/records/011-upgrade-command.md) |

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
└── docs/records/000-011-*.md
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

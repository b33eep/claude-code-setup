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
| Modular Architecture | Done | Base + modules (standards, mcp, skills) |
| Custom Modules | Done | ~/.claude/custom/ for user modules |
| Solo/Team Mode | Done | /init-project asks for .gitignore preference |
| Install Script | Done | --add, --update, --list flags, ShellCheck compliant |
| ADRs | Done | 7 ADRs (000-006) |
| Open Source Release | Done | Published to b33eep/claude-setup |
| GitHub Actions E2E | Done | Full test coverage |
| Open Source Polish | Done | SECURITY.md, CONTRIBUTING.md, CHANGELOG.md, templates |
| README Overhaul | Done | Core Concept prominent, ccstatusline, Plugins, Solo/Team |

### Before v1.0.0

| Todo | Priority | Notes |
|------|----------|-------|
| /todo command | High | Quick capture todos → adds to CLAUDE.md |
| ADR guidance | Medium | Refine when ADR needed in global prompt, or create /adr command, or both |
| Code Review command | High | Create /do-review command, refine when review needed in global prompt |
| Slidev skill attribution | High | Find original source, add proper attribution |
| ccstatusline in install.sh | Low | Auto-configure if not too complex, skip if complex |
| Auto-compact prompt | Low | Ask user in install.sh if they want to disable, skip if complex |
| Java standards + Gradle skill | Medium | Find/create Java coding standards and Gradle build skill |

**Next Step:** Work on v1.0.0 todos (see above)

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
└── docs/adr/000-006-*.md
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

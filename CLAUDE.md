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
| Install Script | Done | --add, --update, --list, --yes flags, ShellCheck compliant |
| Records | Done | 21 Records (000-020) |
| Open Source Release | Done | Published to b33eep/claude-code-setup |
| GitHub Actions E2E | Done | Full test coverage |
| Open Source Polish | Done | SECURITY.md, CONTRIBUTING.md, CHANGELOG.md, templates |
| README Overhaul | Done | Core Concept prominent, ccstatusline, Plugins, Solo/Team |
| Upgrade Commands | Done | /claude-code-setup, /add-custom ([Record 011](docs/records/011-upgrade-command.md)) |
| Records Rename | Done | ADR → Records, added guidance in global prompt |
| --yes Flag Bug Fix | Done | Content v7: Non-interactive updates for /claude-code-setup |
| JavaScript Skill | Done | Content v8: standards-javascript for Node.js/JS projects |
| Skill Creator | Done | Content v9: /skill-creator for custom skill creation ([Record 013](docs/records/013-skill-creator.md)) |
| /claude-code-setup | Done | Content v10: Renamed from /upgrade-claude-setup, shows delta, asks before actions |
| Linux Support | Done | Content v13: OS detection, package manager abstraction ([Record 014](docs/records/014-linux-support.md)) |
| Install Script Refactoring | Done | Content v13: Split into lib/ modules ([Record 015](docs/records/015-install-script-refactoring.md)) |
| Interactive Pipe Install | Done | `bash <(curl ...)` for interactive, `curl \| bash` for --yes mode |
| ccstatusline Object Format | Done | Fix statusLine settings.json format (object, not string) |
| One-liner UX | Done | Show `/claude-code-setup` instead of `./install.sh` for one-liner users |
| Interactive Toggle Selection | Done | Toggle-based module selection with smart defaults, Linux-compatible |
| Arrow-Key Navigation | Done | ↑↓ navigation, space toggle, enter confirm (macOS + Linux) |
| Preserve User Instructions | Done | Content v15: [Record 016](docs/records/016-preserve-user-instructions.md) - Section markers in global CLAUDE.md |
| README Restructure | Done | Problem→Solution flow, Installation steps, all features documented |
| Optional Hooks | Rejected | Hooks cannot invoke Claude commands ([Record 012](docs/records/012-optional-hooks-automation.md)) |
| Rename /clear-session | Done | Content v16: /wrapup for consistency with /catchup ([Record 017](docs/records/017-rename-clear-session-to-wrap-up.md)) |
| /todo Command | Done | Content v18: Add/list todos in CLAUDE.md ([Record 018](docs/records/018-todo-command.md)) |
| Upgrade Permissions | Rejected | Auto-permissions may discourage new users ([Record 019](docs/records/019-upgrade-permissions.md)) |
| Custom Modules E2E Test | Done | Validated: custom repo → /add-custom → /claude-code-setup installs custom:standards-java |
| Custom Modules Versioning | Done | VERSION + CHANGELOG.md in custom repo, tracked in installed.json ([Record 020](docs/records/020-custom-modules-versioning.md)) |

### Future

| Todo | Priority | Problem | Solution |
|------|----------|---------|----------|
| /do-review command | Low | Unclear when to trigger code review, easy to forget | Create command + refine global prompt guidance |

---

## Records

| Decision | Choice | Record |
|----------|--------|--------|
| Core Workflow | /init-project, /wrapup, /catchup | [000](docs/records/000-core-workflow.md) |
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
| Optional Hooks | **Rejected** - Hooks cannot invoke commands | [012](docs/records/012-optional-hooks-automation.md) |
| Skill Creator | Command skill for creating custom skills | [013](docs/records/013-skill-creator.md) |
| Linux Support | OS detection, package manager abstraction | [014](docs/records/014-linux-support.md) |
| Install Script Refactoring | Split into lib/ modules at 1000 lines | [015](docs/records/015-install-script-refactoring.md) |
| Preserve User Instructions | Section markers in global CLAUDE.md | [016](docs/records/016-preserve-user-instructions.md) |
| Rename /clear-session | /wrapup - clearer naming | [017](docs/records/017-rename-clear-session-to-wrap-up.md) |
| /todo Command | Add/list todos, Records for complex ones | [018](docs/records/018-todo-command.md) |
| Upgrade Permissions | **Rejected** - May discourage new users | [019](docs/records/019-upgrade-permissions.md) |
| Custom Modules Versioning | VERSION + installed.json tracking | [020](docs/records/020-custom-modules-versioning.md) |

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
├── lib/                       # Modular install script components
├── templates/
├── mcp/
├── commands/
├── skills/
└── docs/records/000-020-*.md
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

Tests use `expect` for real interactive simulation (toggle selection, API key input, etc.).

### Manual Testing

Test the install script without affecting your real `~/.claude`:

```bash
HOME=/tmp/claude-manual-test && rm -rf $HOME && mkdir -p $HOME && ./install.sh
```

This creates a clean test environment under `/tmp/claude-manual-test/`. After testing:
- Config: `/tmp/claude-manual-test/.claude/`
- MCP: `/tmp/claude-manual-test/.claude.json`

### Bump Content Version

When changing managed content (templates, commands, skills, mcp):

1. Increment `templates/VERSION`
2. Update badge in `README.md` (search for `content-v`)
3. Add CHANGELOG.md entry:
   ```markdown
   ## [Unreleased]
   - Content vX: Description of change
   ```
4. Run tests: `./tests/test.sh`

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

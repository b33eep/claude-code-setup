# Claude Code Setup

## About

A modular, minimal setup for Claude Code with clear workflow and persistent memory via Markdown files. Open source release.

## Tech Stack

- Bash (install.sh)
- Markdown (templates, commands)
- Node.js (MCP servers via npx, Nextra docs site)
- GitHub Actions (CI/CD)

---

## Current Status

| Story | Status | Notes |
|-------|--------|-------|
| — | — | No active work |

**Legend:** Open | In Progress | Done

**Next Step:** Pick from Future table or backlog

### Future

| Todo | Priority | Problem | Solution |
|------|----------|---------|----------|
| /do-review command | Low | Unclear when to trigger code review, easy to forget | Create command + refine global prompt guidance |
| Docker Matrix Tests | Low | deps.json install commands not tested on real distros | GitHub Actions with Docker matrix ([Record 022](docs/records/022-docker-matrix-tests.md)) |
| Slidev skill type review | Low | `create-slidev-presentation` is command but could benefit from auto-loading | Consider changing to context with `applies_to: [slidev]` |

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
| YouTube Transcript Skill | yt-dlp + ffmpeg, frame extraction | [021](docs/records/021-youtube-transcript-skill.md) |
| Docker Matrix Tests | **Planned** - Validate deps.json on distros | [022](docs/records/022-docker-matrix-tests.md) |
| Context Quality Improvements | Decision Log (v23) | [023](docs/records/023-context-quality-improvements.md) |
| Documentation Site | Nextra in /website, monorepo | [024](docs/records/024-documentation-site.md) |
| Private Notes | `.open.md` convention, /catchup integration | [025](docs/records/025-private-notes.md) |
| External Plugins | Install Claude plugins via `claude plugin` CLI | [026](docs/records/026-external-plugins.md) |
| Uninstall/Remove Modules | `--remove` Flag + `/claude-code-setup remove` | [027](docs/records/027-uninstall-modules.md) |
| Update Notifications | SessionStart hook with version check | [028](docs/records/028-update-notifications.md) |
| Documentation User Perspective | Reference → Features, user-facing names | [029](docs/records/029-documentation-user-perspective.md) |
| /design Command | Structured 5-step design workflow | [030](docs/records/030-design-command.md) |
| Java Developer Skill | Core Java standards + framework extensions | [031](docs/records/031-java-developer-skill.md) |
| Kotlin Standards Skill | Core Kotlin + framework extensions (Android, Spring, Ktor later) | [032](docs/records/032-kotlin-standards-skill.md) |
| Gradle Standards Skill | Gradle 9 Kotlin DSL: project config + plugin development | [033](docs/records/033-gradle-standards-skill.md) |
| Workflow Improvements | Correction trigger + re-plan signs | [034](docs/records/034-workflow-improvements.md) |
| Dynamic CLAUDE.md Tables | Dynamic table generation for install/remove | [035](docs/records/035-dynamic-claude-md-tables.md) |

---

## Recent Decisions

| Date | Decision | Why |
|------|----------|-----|

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
├── website/                   # Nextra documentation site
│   ├── components/
│   ├── pages/
│   └── scripts/               # Prebuild generators
└── docs/records/000-035-*.md
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

```bash
HOME=/tmp/claude-manual-test && rm -rf $HOME && mkdir -p $HOME && ./install.sh
```

Creates a clean test environment under `/tmp/claude-manual-test/`.

### Bump Content Version

When changing managed content (templates, commands, skills, mcp):

1. Increment `templates/VERSION`
2. Update badge in `README.md` (search for `content-v`)
3. Add CHANGELOG.md entry
4. Run tests: `./tests/test.sh`

### Documentation Site

When changing commands, skills, or features:

1. Update relevant pages in `website/pages/`
2. Test locally: `cd website && npm run dev`
3. Changes deploy automatically on merge to main

## Repository

https://github.com/b33eep/claude-code-setup

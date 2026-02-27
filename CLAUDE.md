<!-- project-template: 48 -->
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
| Migrate code-review-ai to comprehensive-review | In Progress | PR [#50](https://github.com/b33eep/claude-code-setup/pull/50), review feedback partially applied |

**Legend:** Open | In Progress | Done

**Next Step:** Apply remaining review feedback (fix tracking ordering in update.sh already done, migration test added, test renumbered, partial-failure documented). Run full test suite, push, wait for CI green, merge.

### Future

| Todo | Priority | Problem | Solution |
|------|----------|---------|----------|
| Docker Matrix Tests | Low | deps.json install commands not tested on real distros | GitHub Actions with Docker matrix ([Record 022](docs/records/022-docker-matrix-tests.md)) |
| Slidev skill type review | Low | `create-slidev-presentation` is command but could benefit from auto-loading | Consider changing to context with `applies_to: [slidev]` |

---

## Recent Decisions

| Date | Decision | Why |
|------|----------|-----|
| 2026-02-27 | 2 agents default + `--security`/`--full` flag for 3rd | Balance between review quality and token cost; security-auditor not needed for every review |
| 2026-02-27 | Tracking update after plugin install, not before | Prevents state mismatch if `claude plugin install` fails (review feedback) |
| 2026-02-11 | Replaced team-setup.mdx with customizing.mdx | All custom module topics (skills, commands, scripts, MCP) belong in one page; team-setup was redundant; Solo vs Team already in init-project |

---

## Project Instructions

<!-- PROJECT INSTRUCTIONS START -->

### Pull Request Format

When creating PRs, use this structure (see PRs #45, #46 for examples):

```markdown
## Summary
- Bullet points of what changed

## Problem
Why this change is needed

## Solution
How the problem is solved

## Test plan
- [ ] Test description 1
- [ ] Test description 2
- [ ] All tests pass

## Files Changed (optional)
- List of changed files
```

**Important:**
- Use "Test plan" section with checkboxes, NOT "Actions taken"
- Include `/do-review` results in test plan if applicable
- Keep summary concise (3-5 bullets max)

<!-- PROJECT INSTRUCTIONS END -->

---

## Architecture

**Install-time** and **runtime** are separate concerns:

### Install-time: `install.sh` + `lib/`

The installer is a modular Bash script. `install.sh` is the entry point, sourcing libraries from `lib/`:

| Library | Responsibility |
|---------|---------------|
| `platform.sh` | OS detection (macOS/Ubuntu/Arch/Fedora), package manager |
| `helpers.sh` | Colors, printing, JSON utilities, TTY-aware input, custom command/script install |
| `modules.sh` | Interactive toggle selection UI, module discovery |
| `mcp.sh` | MCP server installation (JSON config → `~/.claude.json`) |
| `skills.sh` | Skill installation + `build_claude_md()` |
| `update.sh` | `--update` mode, content version comparison |
| `uninstall.sh` | `--remove` mode |
| `external-plugins.sh` | Third-party plugin installation (document-skills, comprehensive-review) |
| `statusline.sh` | ccstatusline configuration |
| `hooks.sh` | Claude Code hooks setup |
| `agent-teams.sh` | Agent Teams env var toggle in settings.json |
| `setup-status.sh` | Discovery script for `/claude-code-setup` — outputs JSON status (standalone, NOT sourced by install.sh) |

**Install flow:** detect OS → select modules (interactive toggle) → copy commands to `~/.claude/commands/` → install MCP configs to `~/.claude.json` → copy skills to `~/.claude/skills/` → build global CLAUDE.md from template + dynamic tables → install external plugins → configure statusline/hooks/agent-teams.

### Runtime: Markdown files consumed by Claude Code

Nothing runs at runtime. The installer produces static Markdown files that Claude Code reads:

```
~/.claude/
├── CLAUDE.md              ← Global instructions (built from templates/base/global-CLAUDE.md + dynamic tables)
├── commands/*.md          ← Slash commands (Claude reads on /command invocation)
├── skills/*/SKILL.md      ← Context skills (Claude reads based on tech stack / file type)
└── templates/             ← Project CLAUDE.md template (used by /init-project)

project/
├── CLAUDE.md              ← Project-specific instructions (created by /init-project)
└── docs/records/*.md      ← Design decisions, feature specs (created by /design)
```

### Module types

| Type | Source format | Installed to | Consumed by |
|------|-------------|-------------|-------------|
| Commands | `commands/*.md` | `~/.claude/commands/` | Claude on `/command` |
| Skills | `skills/*/SKILL.md` | `~/.claude/skills/*/` | Claude via auto-loading (tech stack match or file extension) |
| MCP servers | `mcp/*.json` | `~/.claude.json` (merged) | Claude Code MCP client |
| Templates | `templates/*.md` | `~/.claude/templates/` | `/init-project`, `/catchup` (migration) |

### Content versioning

`templates/VERSION` tracks all managed content. `<!-- project-template: N -->` in `templates/project-CLAUDE.md` tracks template structure separately. The installer compares installed vs available versions for `--update`.

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
├── skills/                    # Coding standards + tool skills
│   └── user-stories/          # INVEST stories, Given-When-Then AC
├── website/                   # Nextra documentation site
│   ├── components/
│   ├── pages/
│   └── scripts/               # Prebuild generators
└── docs/records/
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

**Two separate versions — don't confuse them:**

| Version | File | Tracks | Bump when |
|---------|------|--------|-----------|
| Content version | `templates/VERSION` | All managed content (commands, skills, MCP, templates) | Any managed content changes |
| Template version | `<!-- project-template: N -->` in `templates/project-CLAUDE.md` | Project CLAUDE.md structure only | Set to current content version when template structure changes |

Content version >= template version. Adding a command bumps content version but NOT the template version (template didn't change). When `project-CLAUDE.md` itself changes, set template version = content version (don't increment independently).

### Documentation Site

When changing commands, skills, or features:

1. Update relevant pages in `website/pages/`
2. Test locally: `cd website && npm run dev`
3. Changes deploy automatically on merge to main

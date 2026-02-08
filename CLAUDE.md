<!-- project-template: 46 -->
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
| User Stories Skill | In Progress | [Record 039](docs/records/039-user-stories-skill.md) — Stories 1-3 done, needs commit + PR + docs page |

**Legend:** Open | In Progress | Done

**Next Step:** Commit user-stories skill changes, create PR, add docs page (website/pages/)

### Future

| Todo | Priority | Problem | Solution |
|------|----------|---------|----------|
| Docker Matrix Tests | Low | deps.json install commands not tested on real distros | GitHub Actions with Docker matrix ([Record 022](docs/records/022-docker-matrix-tests.md)) |
| Slidev skill type review | Low | `create-slidev-presentation` is command but could benefit from auto-loading | Consider changing to context with `applies_to: [slidev]` |

---

## Recent Decisions

| Date | Decision | Why |
|------|----------|-----|
| 2026-02-08 | User-stories skill as command type (not context) | Invoked explicitly via /design Step 4 or manually, not auto-loaded per Tech Stack. |
| 2026-02-08 | Adapted agile-product-owner, stripped sprint/velocity/epic | User story focus only — sprint planning is out of scope for claude-code-setup. |

---

## Project Instructions

<!-- PROJECT INSTRUCTIONS START -->
Add project-specific instructions, preferences, and conventions here.
This section is preserved during template migrations and /wrapup.

Examples:
- Testing preferences
- Deployment conventions
- Project-specific coding rules
<!-- PROJECT INSTRUCTIONS END -->

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

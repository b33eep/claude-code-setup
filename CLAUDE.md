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
| Agent Teams Commands | Done | [Record 038](docs/records/038-pair-programming-with-agent-teams.md) — All 4 stories complete |

**Legend:** Open | In Progress | Done

**Next Step:** Story 4 — templates (global CLAUDE.md with both commands), docs pages, version bump, release

### Future

| Todo | Priority | Problem | Solution |
|------|----------|---------|----------|
| /do-review command | Low | Unclear when to trigger code review, easy to forget | Create command + refine global prompt guidance |
| Docker Matrix Tests | Low | deps.json install commands not tested on real distros | GitHub Actions with Docker matrix ([Record 022](docs/records/022-docker-matrix-tests.md)) |
| Slidev skill type review | Low | `create-slidev-presentation` is command but could benefit from auto-loading | Consider changing to context with `applies_to: [slidev]` |

---

## Recent Decisions

| Date | Decision | Why |
|------|----------|-----|
| 2026-02-08 | Two commands: `/with-advisor` + `/delegate` | Different use cases: augmentation (expert monitors your work) vs delegation (teammate works independently). |
| 2026-02-08 | Pattern B over Pattern A | Human needs full visibility. Pattern A (delegation) left human blind. Pattern B (Main + Advisors) validated via PoC. |
| 2026-02-08 | Advisor onboarding = `/catchup` + role | Reuses existing infrastructure. No custom onboarding needed. |
| 2026-02-08 | Delegate write isolation via `git worktree` | Prevents conflicts between Main and delegate working in same repo. |
| 2026-02-08 | Agent Teams as install wizard toggle | Command always installed, Agent Teams env var as separate opt-in. Runtime check with hint if not enabled. |
| 2026-02-08 | /with-advisor: principle over checklists for task complexity | Claude can judge "overhead exceeds benefit" itself. Hardcoded lists restrict and don't add value. |
| 2026-02-08 | Dynamic team names for /delegate (`delegate-[slug]`) | Fixed name would block concurrent delegates. Slug-based naming enables multiple parallel delegations. |
| 2026-02-08 | `-B` flag for worktree branch creation | `-b` fails if branch exists from previous run. `-B` resets gracefully, better UX for reruns. |
| 2026-02-08 | /with-advisor scales to short tasks as async reviewer | Advisor onboards slower than fast implementations. Works as post-hoc review — still valuable. Documented in Record 038. |

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
├── skills/
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
| Template version | `<!-- project-template: N -->` in `templates/project-CLAUDE.md` | Project CLAUDE.md structure only | Template structure changes |

Content version >= template version. Adding a command bumps content version but NOT the template version (template didn't change). Only bump both when `project-CLAUDE.md` itself changes.

### Documentation Site

When changing commands, skills, or features:

1. Update relevant pages in `website/pages/`
2. Test locally: `cd website && npm run dev`
3. Changes deploy automatically on merge to main

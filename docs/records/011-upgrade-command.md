# Record 011: Installation & Upgrade

**Status:** Accepted
**Date:** 2025-01-24

## Context

claude-setup extends Claude Code with workflows, commands, and skills. There are multiple user scenarios:

| Scenario | User Situation | Current Approach |
|----------|----------------|------------------|
| **Initial Install** | Has Claude Code, wants claude-setup | `git clone` → `cd` → `./install.sh` |
| **Upgrade Base** | Has claude-setup, wants new version | `cd repo` → `git pull` → `./install.sh --update` |
| **Add Custom** | Company/user has private repo | `git clone company-repo ~/.claude/custom` |
| **Upgrade Custom** | Custom repo has updates | `cd ~/.claude/custom && git pull` |

Problems:
- Multiple steps requiring terminal context-switching
- Inconsistent UX between base and custom
- Git knowledge required for everything

## Decision

Four Claude commands covering all scenarios:

| Action | Method | Git Required? |
|--------|--------|---------------|
| **Install Base** | `curl ... \| bash` | No |
| **Upgrade Base** | `/claude-code-setup` | No (hidden) |
| **Add Custom** | `/add-custom <url>` | No (hidden) |
| **Upgrade Custom** | `/upgrade-custom` | No (hidden) |

Git operations are hidden behind Claude commands. User stays in Claude Code.

## Implementation

### 1. Initial Installation: curl one-liner

```bash
curl -fsSL https://raw.githubusercontent.com/b33eep/claude-setup/main/quick-install.sh | bash
```

**quick-install.sh:**
```bash
#!/bin/bash
set -euo pipefail

echo "Installing claude-setup..."

temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT

git clone --depth 1 https://github.com/b33eep/claude-setup.git "$temp_dir"
cd "$temp_dir"
./install.sh

echo ""
echo "Done! Start Claude Code and run /init-project"
```

**Shell compatibility:** Uses `bash` explicitly in shebang and curl pipe. Works regardless of user's default shell (zsh, fish, etc.) as long as bash is installed (standard on macOS/Linux).

### 2. Upgrade Base: `/claude-code-setup`

`commands/claude-code-setup.md` - Claude executes in 3 phases:

**Phase 1: Check Status**
1. Read current version from `~/.claude/installed.json`
2. Fetch latest version from GitHub (`templates/VERSION`)
3. Clone repo to temp (needed for module discovery)
4. Calculate delta: available modules vs installed modules

**Phase 2: Show Status & Ask User**
5. Present findings (version diff, new modules)
6. Ask user what to do (upgrade, install modules, both, nothing)

**Phase 3: Execute**
7. Perform upgrade and/or install modules based on user choice
8. Cleanup temp directory

### 3. Add Custom: `/add-custom <url>` (NEW)

`commands/add-custom.md` - Claude executes:

1. Validate URL format (git@... or https://..., reject plain http://)
2. Check if `~/.claude/custom` already exists
   - If exists and is git repo: check remote with `git remote get-url origin`
     - Same URL: skip clone, just pull
     - Different URL: warn and abort
   - If exists but not git repo: warn and abort
3. Run `git clone <url> ~/.claude/custom`
4. Show available modules: "Found 3 skills, 2 MCP servers"
5. Hint: "Run install.sh --add to select and install modules"

**Error handling:**
```
Auth failure:
  "Clone failed: Permission denied (publickey).
   Your SSH key isn't configured for this repo.
   Contact your admin or check your SSH setup."

Invalid URL:
  "Invalid Git URL. Expected format:
   - git@company.com:team/repo.git
   - https://github.com/company/repo.git"
```

### 4. Upgrade Custom: `/upgrade-custom` (NEW)

`commands/upgrade-custom.md` - Claude executes:

1. Check if `~/.claude/custom` directory exists
   - If not: "No custom repo found. Use /add-custom <url> first."
2. Check if it's a git repo (`~/.claude/custom/.git` exists)
   - If not: "~/.claude/custom exists but is not a git repo."
3. Run `cd ~/.claude/custom && git pull`
4. Show what changed: "Updated: 2 files changed"
5. Hint: "Run /catchup to reload context"

### Version Management

| File | Purpose |
|------|---------|
| `templates/VERSION` | Source of truth in repo |
| `~/.claude/installed.json` | Locally installed version (`content_version` field) |
| `~/.claude/custom/.git/config` | Custom repo URL (via `git remote get-url origin`) |

No separate `.custom-source` file needed - Git already stores the remote URL.

### Template Strategy

**Problem:** The project template was embedded in `~/.claude/CLAUDE.md`. This wastes context tokens because:
- `~/.claude/CLAUDE.md` is loaded in EVERY session
- The template is only needed once per project (at `/init-project`)
- After `/catchup`, the project's own `CLAUDE.md` is loaded anyway

**Solution:** Separate template file.

| Location | File | Purpose |
|----------|------|---------|
| **Repo** | `templates/project-CLAUDE.md` | Source template |
| **Installed** | `~/.claude/templates/CLAUDE.template.md` | Used by `/init-project` |

**Changes required:**
1. Remove embedded template from `templates/base/global-CLAUDE.md`
2. Update `install.sh` to copy template with new name
3. Update `/init-project` command to read from `~/.claude/templates/CLAUDE.template.md`

## File Structure After Full Installation

```
~/.claude/
├── CLAUDE.md                      # Global instructions (no embedded template)
├── installed.json                 # {"content_version": 5, "mcp": [], "skills": []}
├── commands/
│   ├── init-project.md
│   ├── catchup.md
│   ├── clear-session.md
│   ├── claude-code-setup.md
│   ├── add-custom.md              # NEW
│   └── upgrade-custom.md          # NEW
├── templates/
│   └── CLAUDE.template.md         # Project template
├── skills/
│   └── ...
└── custom/                        # Company repo (optional)
    ├── .git/                      # Git stores remote URL here
    ├── skills/
    └── mcp/
```

## User Journeys

### Solo User (no custom)
```
Terminal:  curl ... | bash
Claude:    /init-project  →  Start working
Later:     /claude-code-setup  →  Updated
```

### Company User (with custom)
```
Terminal:  curl ... | bash
Claude:    /add-custom git@company.com:claude-custom.git
           → "Found 3 skills. Run install.sh --add to install."
Terminal:  install.sh --add  →  Select company modules
Claude:    /init-project  →  Start working
Later:     /claude-code-setup  →  Base updated
           /upgrade-custom  →  Company modules updated
```

### Company Onboarding (documented for companies)
```
Companies can document for their devs:

1. Install claude-setup:
   curl -fsSL https://raw.githubusercontent.com/b33eep/claude-setup/main/quick-install.sh | bash

2. In Claude Code, add company modules:
   /add-custom git@company.com:claude-custom.git

3. Install company modules:
   install.sh --add
```

## Testing Strategy

| Test | Challenge | Approach |
|------|-----------|----------|
| curl one-liner | Needs published script | Test after merge to main; or local HTTP server |
| /claude-code-setup | Needs version difference | Create mock with two versions in temp dirs |
| /add-custom | Needs Git repo | Create local bare repo in test |
| /upgrade-custom | Needs repo with new commits | Local repo, add commit, test pull |

**Test scenarios to add:**
1. `06-quick-install.sh` - Fresh install via curl (post-release)
2. `07-add-custom.sh` - Add custom from local bare repo
3. `08-upgrade-custom.sh` - Pull changes from custom repo

## Implementation Plan

### Iteration 1: Template Separation (Foundation)

**Goal:** Extract embedded template from global-CLAUDE.md to separate file

| Task | File | Action |
|------|------|--------|
| 1.1 | `templates/project-CLAUDE.md` | Create with extracted template content |
| 1.2 | `install.sh` | Add copy logic: `templates/project-CLAUDE.md` → `~/.claude/templates/CLAUDE.template.md` |
| 1.3 | `templates/base/global-CLAUDE.md` | Remove embedded template (lines 212-260), update reference |
| 1.4 | `commands/init-project.md` | Update to read from `~/.claude/templates/CLAUDE.template.md` |
| 1.5 | Tests | Update existing tests to verify template installation |

**Acceptance:** Fresh install creates `~/.claude/templates/CLAUDE.template.md`

---

### Iteration 2: quick-install.sh

**Goal:** Enable `curl ... | bash` installation for new users

| Task | File | Action |
|------|------|--------|
| 2.1 | `quick-install.sh` | Create script (clone to temp, run install.sh, cleanup) |
| 2.2 | `README.md` | Update installation section with curl one-liner |
| 2.3 | Test | Manual test after merge to main (curl requires published file) |

**Acceptance:** `curl -fsSL .../quick-install.sh | bash` installs successfully

---

### Iteration 3: /claude-code-setup Refinement

**Goal:** Finalize and test the upgrade command

| Task | File | Action |
|------|------|--------|
| 3.1 | `commands/claude-code-setup.md` | Review, ensure CHANGELOG.md integration |
| 3.2 | Test | Manual test: version comparison, upgrade flow, rollback |

**Acceptance:** Command detects version difference, upgrades, shows changelog

---

### Iteration 4: /add-custom Command

**Goal:** Allow adding custom module repos via Claude command

| Task | File | Action |
|------|------|--------|
| 4.1 | `commands/add-custom.md` | Create command (validate URL, clone to ~/.claude/custom, show modules) |
| 4.2 | `tests/scenarios/07-add-custom.sh` | Test with local bare repo |

**Acceptance:** `/add-custom git@...` clones repo, shows available modules

---

### Iteration 5: /upgrade-custom Command

**Goal:** Allow upgrading custom repo via Claude command

| Task | File | Action |
|------|------|--------|
| 5.1 | `commands/upgrade-custom.md` | Create command (check repo, git pull, show changes) |
| 5.2 | `tests/scenarios/08-upgrade-custom.sh` | Test with local repo, add commit, verify pull |

**Acceptance:** `/upgrade-custom` pulls changes, shows what was updated

---

### Iteration 6: Documentation & Release

**Goal:** Finalize documentation and prepare release

| Task | File | Action |
|------|------|--------|
| 6.1 | `README.md` | Update with all new commands, user journeys |
| 6.2 | `CHANGELOG.md` | Add all changes from iterations 1-5 |
| 6.3 | `templates/VERSION` | Bump version |
| 6.4 | Tests | Run full test suite, verify all scenarios pass |

**Acceptance:** All tests pass, documentation complete

---

### Iteration Summary

| # | Name | Status | Dependencies |
|---|------|--------|--------------|
| 1 | Template Separation | Done | - |
| 2 | quick-install.sh | Done | - |
| 3 | /claude-code-setup | Done | 1 |
| 4 | /add-custom | Done | - |
| 5 | /upgrade-custom | Done | 4 |
| 6 | Documentation & Release | Done | 1-5 |

## Consequences

### Positive

- Single command for new users (no Git knowledge needed)
- All updates via Claude commands (no terminal context-switch)
- Consistent UX for base and custom
- Companies get simple onboarding docs
- Git operations hidden but still available for power users

### Negative

- Four commands to maintain
- Auth errors still possible (SSH keys, tokens)
- Custom repo management is user's responsibility
- More test scenarios needed

## Rollback

If something fails:
```bash
# Base
cd /path/to/claude-setup && git pull && ./install.sh --update

# Custom
cd ~/.claude/custom && git pull
```

## References

- [Record 002: Custom Modules Directory](002-custom-modules-directory.md)
- [Record 008: Content Versioning](008-content-versioning.md)

# Record 040: /claude-code-setup UX — Reduce Permission Prompts

## Status

Done

---

## Problem

`/claude-code-setup` makes ~12-18 individual Bash calls during the discovery phase (curl, git clone, ls, jq reads, etc.). Each triggers a permission prompt. With a custom repo configured, the count is even higher (git fetch, cat VERSION, git show, ls custom/skills, ls custom/mcp, jq custom_version).

The user clicks through a wall of approvals for purely read-only operations before anything useful happens. This makes the central management command frustrating to use, pushing users toward manual `./install.sh` instead.

**Goal:** Reduce to ~2 permission prompts regardless of scenario (1 discover + 1 execute).

## Options Considered

Evaluated Script vs Subagent for both Discovery and Execution phases. All subagent variants add complexity without reducing prompt count below 2. Discovery Script wins (testbar, debuggable, fits `lib/` pattern). Execution doesn't need a script since existing install.sh commands are chainable — except `--remove` which is interactive. Solution: add `--remove-skill`/`--remove-mcp` flags.

### Decision

Discovery Script + non-interactive remove flags. Simplest approach with maximum impact.

## Solution

### Overview

Three changes:

1. **`lib/setup-status.sh`** — Discovery script, outputs JSON (replaces 8-12 Bash calls with 1)
2. **`--remove-skill X` / `--remove-mcp X`** — Non-interactive removal flags for install.sh
3. **Updated `commands/claude-code-setup.md`** — Uses new script + chainable commands

### New Flow (2 prompts)

```
Prompt 1:  Clone + setup-status.sh → JSON
           Claude parses JSON, shows status
           AskUserQuestion (multiSelect) → User picks actions
Prompt 2:  Chained execution + cleanup
```

### Part 1: `lib/setup-status.sh`

Single script that gathers ALL discovery info and outputs JSON to stdout.

**Important:** `setup-status.sh` is a standalone executable invoked by the command markdown. It is NOT sourced by `install.sh` and should NOT be added to the source chain in `install.sh`.

**Invocation** (from the command markdown — 1 Bash call):
```bash
temp=$(mktemp -d /tmp/claude-setup-XXXXXX) && \
git clone --depth 1 https://github.com/b33eep/claude-code-setup.git "$temp" 2>/dev/null && \
"$temp/lib/setup-status.sh"
```

**Variable initialization:** The script runs from within the cloned repo but needs access to the user's installation. It must set these variables before sourcing any helpers:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
CUSTOM_DIR="$CLAUDE_DIR/custom"
INSTALLED_FILE="$CLAUDE_DIR/installed.json"
CONTENT_VERSION_FILE="$SCRIPT_DIR/templates/VERSION"
MCP_CONFIG_FILE="$HOME/.claude.json"
```

**What it does:**
1. Read `~/.claude/installed.json` (installed version, modules)
2. Read `templates/VERSION` from cloned repo (available version)
3. Compare installed vs available skills/MCP → find new (uninstalled) modules
4. Read `external-plugins.json` + `installed.json` → find available/installed plugins (does NOT call `claude` CLI — uses tracking data only)
5. Check `~/.claude/settings.json` for Agent Teams status
6. Check custom repo (if `~/.claude/custom` exists): `git fetch`, compare VERSION
7. Output JSON to stdout

**Note on module discovery:** The script should NOT source `lib/modules.sh` (which pulls in `interactive_select` and terminal control code). Instead, it implements module discovery directly — listing directories/files and comparing against `installed.json` via jq.

**Note on CHANGELOG:** The script does NOT parse CHANGELOG.md. Claude reads the CHANGELOG directly from the cloned repo (`$temp/CHANGELOG.md`) after receiving the JSON, if an upgrade is available. This avoids fragile text parsing in bash.

**Output JSON:**
```json
{
  "temp_dir": "/tmp/claude-setup-XXXXXX",
  "base": {
    "installed": 50,
    "available": 52,
    "update_available": true
  },
  "custom": {
    "configured": true,
    "installed": 1,
    "available": 2,
    "update_available": true
  },
  "new_modules": {
    "skills": ["standards-kotlin"],
    "mcp": ["brave-search"],
    "plugins": ["document-skills"]
  },
  "installed_modules": {
    "skills": ["standards-python", "standards-shell"],
    "mcp": ["pdf-reader", "google-search"],
    "plugins": ["code-review-ai@claude-code-workflows"]
  },
  "agent_teams": {
    "enabled": true
  }
}
```

**Error cases:**
- No network (clone fails) → script isn't reached, Bash call fails, command shows manual fallback
- No `installed.json` → output `{"error": "not_installed"}`
- jq not found → output plain text error (shouldn't happen, jq is a dependency)
- Custom repo configured but unreachable → `custom.configured: true`, `custom.update_available: false`, no error thrown
- `claude` CLI not available → does not affect discovery (uses installed.json tracking only)

**Implementation notes:**
- Sources `lib/helpers.sh` for `get_installed`, `get_content_version`, `is_installed` etc.
- Uses jq to build output JSON (no manual string concatenation)
- Script is NOT standalone — runs from within the cloned repo (has access to SCRIPT_DIR)
- stderr for diagnostic messages, stdout reserved for JSON only

### Part 2: `--remove-skill X` / `--remove-mcp X`

Add to `install.sh` to make removal non-interactive. Mirrors existing `--add-skill`/`--add-mcp` pattern.

**New CLI:**
```bash
./install.sh --remove-skill standards-kotlin
./install.sh --remove-mcp brave-search
./install.sh --remove-skill custom:my-skill
./install.sh --remove-mcp custom:my-mcp
```

**`do_remove_skill()` — placed in `install.sh`** (alongside `do_add_skill()`, following the `do_*` pattern):
1. Validate skill exists in installed.json (or filesystem)
2. Call existing `uninstall_skill()` from `lib/uninstall.sh` (removes dir + tracking)
3. Call `build_claude_md()` (rebuilds tables without removed skill)

**`do_remove_mcp()` — placed in `install.sh`** (alongside `do_add_mcp()`):
1. Validate MCP exists in installed.json (or `~/.claude.json`)
2. Call existing `uninstall_mcp()` from `lib/uninstall.sh` (removes from claude.json + tracking)
3. Call `build_claude_md()` (rebuilds tables without removed MCP)

**Arg parsing** (in `main()`):
```bash
--remove-skill)
    action="remove-skill"
    shift
    if [[ $# -eq 0 ]]; then
        print_error "--remove-skill requires a skill name"
        echo "Usage: ./install.sh --remove-skill <skill-name>"
        exit 1
    fi
    remove_skill_name="$1"
    ;;
--remove-mcp)
    action="remove-mcp"
    shift
    if [[ $# -eq 0 ]]; then
        print_error "--remove-mcp requires an MCP server name"
        echo "Usage: ./install.sh --remove-mcp <mcp-name>"
        exit 1
    fi
    remove_mcp_name="$1"
    ;;
```

**Note on multiple removes in one chain:** Each `--remove-skill`/`--remove-mcp` call triggers `build_claude_md()`. When chained (`--remove-skill A && --remove-skill B`), the rebuild runs twice. This is idempotent and harmless. Optimization (e.g., `--skip-rebuild` flag) is not needed now.

**Plugin removal:** Not adding `--remove-plugin` — Claude chains `claude plugin remove X` + jq tracking update directly. Plugin removal is rare and already non-interactive. The explicit jq filter for tracking:
```bash
jq '.external_plugins = (.external_plugins // [] | map(select(. != "PLUGIN_ID@MARKETPLACE")))' \
  ~/.claude/installed.json > ~/.claude/installed.json.tmp && \
  mv ~/.claude/installed.json.tmp ~/.claude/installed.json
```

**Disable Agent Teams:** Intentionally excluded from this feature. Users who want to disable Agent Teams can edit `~/.claude/settings.json` directly. The command does not offer a toggle-off option.

### Part 3: Updated Command Markdown

The command becomes three clean phases.

**Phase 1 — Discovery (1 Bash call):**
```bash
temp=$(mktemp -d /tmp/claude-setup-XXXXXX) && \
git clone --depth 1 https://github.com/b33eep/claude-code-setup.git "$temp" 2>/dev/null && \
"$temp/lib/setup-status.sh"
```
Parse JSON output. If error → show message, exit.

If `base.update_available` is true, also read the CHANGELOG for relevant entries:
```bash
# Claude reads this from the cloned repo (already available, no extra Bash call needed)
# Read $temp/CHANGELOG.md using the Read tool
```

**Phase 2 — Present + Ask (0 Bash calls):**

Show status summary (same format as current command). Then AskUserQuestion with multiSelect. Options generated dynamically based on JSON:
- "Upgrade base (vX → vY)" — if `base.update_available`
- "Upgrade custom (vX → vY)" — if `custom.update_available`
- "Install [module-name]" — for each entry in `new_modules.*`
- "Remove modules" — if installed modules exist
- "Enable Agent Teams" — if `agent_teams.enabled == false`

If "Remove modules" selected → second AskUserQuestion listing installed modules from JSON.
If "Install modules" and >4 available → second AskUserQuestion for selection.

**Phase 3 — Execute (1 Bash call):**

Build a single chained command based on user selections.

**Important: Cleanup uses `;` not `&&`** — ensures temp dir is removed even if a command in the chain fails:
```bash
cd $temp && ./install.sh --update --yes && ./install.sh --add-skill X ; rm -rf $temp
```

Execution chains for all scenarios:

| User Choice | Execution Chain |
|-------------|----------------|
| Upgrade base only | `cd $temp && ./install.sh --update --yes ; rm -rf $temp` |
| Upgrade custom only | `git -C ~/.claude/custom pull && new_v=$(cat ~/.claude/custom/VERSION 2>/dev/null \|\| echo "0") && jq --arg v "$new_v" '.custom_version = ($v \| tonumber)' ~/.claude/installed.json > ~/.claude/installed.json.tmp && mv ~/.claude/installed.json.tmp ~/.claude/installed.json ; rm -rf $temp` |
| Upgrade base + custom | Base chain `&&` custom chain `;` cleanup |
| Install skill | `cd $temp && ./install.sh --add-skill X ; rm -rf $temp` |
| Install MCP (no key) | `cd $temp && ./install.sh --add-mcp X ; rm -rf $temp` |
| Install MCP (API key) | Claude inserts config directly into `~/.claude.json` with `YOUR_API_KEY_HERE` placeholder via jq (bypasses `--add-mcp` which prompts interactively) `;` cleanup |
| Remove skill | `cd $temp && ./install.sh --remove-skill X ; rm -rf $temp` |
| Remove MCP | `cd $temp && ./install.sh --remove-mcp X ; rm -rf $temp` |
| Upgrade + install | `cd $temp && ./install.sh --update --yes && ./install.sh --add-skill X ; rm -rf $temp` |
| Upgrade + remove | `cd $temp && ./install.sh --update --yes && ./install.sh --remove-mcp X ; rm -rf $temp` |
| Multiple installs + removes | `cd $temp && ./install.sh --update --yes && ./install.sh --add-skill X && ./install.sh --remove-skill Y ; rm -rf $temp` |
| Enable Agent Teams only | `jq '.env = (.env // {}) | .env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"' ~/.claude/settings.json > ~/.claude/settings.json.tmp && mv ~/.claude/settings.json.tmp ~/.claude/settings.json ; rm -rf $temp` |
| Install plugin | `claude plugin marketplace add REPO 2>/dev/null; claude plugin install ID@MP && jq '.external_plugins = ((.external_plugins // []) + ["ID@MP"] \| unique)' ~/.claude/installed.json > ~/.claude/installed.json.tmp && mv ~/.claude/installed.json.tmp ~/.claude/installed.json ; rm -rf $temp` |
| Remove plugin | `claude plugin remove ID && jq '.external_plugins = (.external_plugins // [] \| map(select(. != "ID@MP")))' ~/.claude/installed.json > ~/.claude/installed.json.tmp && mv ~/.claude/installed.json.tmp ~/.claude/installed.json ; rm -rf $temp` |

**Note on `do_update()` exit behavior:** `do_update()` in `lib/update.sh` uses `exit 0` (not `return 0`) when already up-to-date. This is safe for chains because exit 0 is success — the next `&&` command still runs. But this is fragile if `do_update()` ever changes to exit non-zero for "nothing to update." Worth noting for future maintenance.

### Prompt Count Summary

| Scenario | Before | After |
|----------|--------|-------|
| Check status (no action) | ~10 | 1 |
| Upgrade only | ~12 | 2 |
| Upgrade + install module | ~14 | 2 |
| Install module only | ~12 | 2 |
| Remove module | ~12 | 2 |
| Upgrade + remove | ~14 | 2 |
| Enable Agent Teams only | ~12 | 2 |
| Everything combined | ~18 | 2 |
| With custom repo | ~18 | 2 |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/setup-status.sh` | Create | Discovery script (standalone, NOT sourced by install.sh) |
| `install.sh` | Modify | Add `do_remove_skill()`, `do_remove_mcp()` + arg parsing for `--remove-skill`, `--remove-mcp` |
| `commands/claude-code-setup.md` | Rewrite | New 3-phase flow |
| `tests/scenarios/XX-setup-status.sh` | Create | Test for discovery script |
| `tests/scenarios/XX-remove-direct.sh` | Create | Test for new remove flags |

## User Stories

### Story 1: Discovery Script

**As a** setup user,
**I want** all status checks to complete in a single operation,
**So that** I see my installation status without approving 12+ permission prompts.

**Acceptance Criteria:**

```
Given a user has claude-code-setup installed (installed.json exists),
When the setup-status.sh script runs from a cloned repo,
Then it outputs valid JSON to stdout with:
  - .base.installed matching content_version from installed.json
  - .base.available matching templates/VERSION from the repo
  - .base.update_available == true when installed < available
  - .installed_modules.skills containing each skill from installed.json
  - .installed_modules.mcp containing each MCP from installed.json
  - .new_modules.skills containing skills in repo but NOT in installed.json
  - .new_modules.mcp containing MCP servers in repo but NOT in installed.json
  - .agent_teams.enabled matching CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS in settings.json
```

```
Given a user has a custom repo configured (~/.claude/custom exists with a git remote),
When setup-status.sh runs,
Then the JSON includes custom.configured: true, custom.installed, custom.available, and custom.update_available.
```

```
Given a user has no custom repo (~/.claude/custom does not exist),
When setup-status.sh runs,
Then the JSON contains custom.configured: false and omits custom version fields.
```

```
Given a custom repo is configured but the remote is unreachable,
When setup-status.sh runs,
Then the JSON contains custom.configured: true, custom.update_available: false, and no error is thrown.
```

```
Given installed.json does not exist,
When setup-status.sh runs,
Then it outputs {"error": "not_installed"}.
```

```
Given the script runs,
When it writes diagnostic messages,
Then diagnostics go to stderr and only valid JSON goes to stdout.
```

**Priority:** High
**Status:** Done

**Test coverage:** Scenario 26 (31 assertions). Custom repo positive/unreachable cases not tested (require git remote and network mock).

---

### Story 2: Non-Interactive Remove Flags

**As a** setup user,
**I want** to remove a specific module by name via command line,
**So that** module removal can be chained with other install.sh operations without interactive prompts.

**Acceptance Criteria:**

```
Given a skill "standards-kotlin" is installed,
When I run ./install.sh --remove-skill standards-kotlin,
Then the skill directory is removed from ~/.claude/skills/, installed.json is updated, and CLAUDE.md is rebuilt without the skill.
```

```
Given an MCP server "brave-search" is installed,
When I run ./install.sh --remove-mcp brave-search,
Then the server is removed from ~/.claude.json, installed.json is updated, and CLAUDE.md is rebuilt without the server.
```

```
Given a custom skill "custom:my-skill" is installed,
When I run ./install.sh --remove-skill custom:my-skill,
Then it handles the custom: prefix correctly and removes the skill.
```

```
Given a skill "nonexistent" is NOT installed,
When I run ./install.sh --remove-skill nonexistent,
Then it shows a warning and exits with 0 (idempotent, matches --add-skill/--add-mcp pattern).
```

```
Given --remove-skill is called without a name argument,
When install.sh parses arguments,
Then it shows a usage error and exits.
```

```
Given I chain --update --yes and --remove-skill as separate calls (./install.sh --update --yes && ./install.sh --remove-skill X),
When both commands execute sequentially,
Then upgrade completes first, then removal completes, both successfully.
```

**Priority:** High
**Status:** Done

**Test coverage:** Scenario 27 (20 assertions). Custom prefix removal (custom:my-skill) not tested (requires custom repo fixture).

---

### Story 3: Command Markdown Rewrite

**As a** setup user,
**I want** `/claude-code-setup` to use the discovery script and chainable commands,
**So that** any scenario (upgrade, install, remove, or combination) completes in 2 permission prompts.

**Acceptance Criteria:**

```
Given the command runs Phase 1 (discovery),
When Claude executes the clone + setup-status.sh,
Then it is a single Bash call that produces parseable JSON.
```

```
Given the JSON shows an available upgrade,
When Claude presents the status and the user selects "Upgrade base",
Then Claude builds a single chained Bash command (cd $temp && ./install.sh --update --yes ; rm -rf $temp) as one permission prompt.
```

```
Given the user selects multiple actions (e.g., upgrade + install skill + enable Agent Teams),
When Claude builds the execution chain,
Then all install.sh operations are chained into one Bash call with ; rm -rf $temp for cleanup.
```

```
Given the user selects "Remove modules",
When Claude asks which modules to remove,
Then it uses AskUserQuestion (not a Bash call) listing installed modules from the JSON.
```

```
Given the user selects only "Enable Agent Teams",
When Claude executes,
Then it runs a jq command + cleanup without needing cd $temp or install.sh.
```

```
Given the user selects "Nothing" or all is up-to-date,
When Phase 2 completes,
Then Claude cleans up the temp dir and shows "All up-to-date".
```

```
Given the user selects an MCP server that requires an API key (e.g., brave-search),
When Claude builds the execution chain,
Then it uses jq to insert the config into ~/.claude.json with YOUR_API_KEY_HERE placeholder instead of calling --add-mcp (which would prompt interactively).
```

```
Given any execution chain fails midway,
When the Bash call completes,
Then the temp dir is still cleaned up (cleanup uses ; not &&).
```

**Priority:** High
**Status:** Done

**Test coverage:** Scenario 09 (42 assertions).

---

### Story 4: Tests for New Functionality

**As a** developer,
**I need** automated tests for setup-status.sh and --remove-skill/--remove-mcp,
**So that** regressions are caught before release.

**Acceptance Criteria:**

```
Given a test environment with installed modules,
When tests/scenarios/XX-setup-status.sh runs,
Then setup-status.sh outputs valid JSON where:
  - .base.installed matches content_version from installed.json
  - .base.available matches templates/VERSION
  - .base.update_available is correct (true or false)
  - .installed_modules.skills lists tracked skills
  - .new_modules.skills lists uninstalled skills from the repo
  - .agent_teams.enabled matches settings.json state
  - .temp_dir is a valid directory path
```

```
Given a test environment with a skill installed,
When tests/scenarios/XX-remove-direct.sh runs --remove-skill,
Then the skill directory no longer exists, installed.json no longer contains it, and CLAUDE.md is rebuilt.
```

```
Given a test environment with an MCP server installed,
When tests/scenarios/XX-remove-direct.sh runs --remove-mcp,
Then the server is removed from both ~/.claude.json and installed.json, and CLAUDE.md is rebuilt.
```

```
Given a test calls --remove-skill with a nonexistent skill,
When the test runs,
Then it verifies the command exits with non-zero status and shows a warning.
```

**Priority:** Medium
**Status:** Done

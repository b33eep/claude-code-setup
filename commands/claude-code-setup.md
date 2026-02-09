# Claude Code Setup

Manage your claude-code-setup installation: check status, upgrade, install, and remove modules.

**Goal:** Any scenario completes in 2 permission prompts (1 discover + 1 execute).

## Phase 1: Discovery (1 Bash call)

Clone repo and run setup-status.sh in a single Bash call:

```bash
temp=$(mktemp -d /tmp/claude-setup-XXXXXX) && \
git clone --depth 1 https://github.com/b33eep/claude-code-setup.git "$temp" 2>/dev/null && \
"$temp/lib/setup-status.sh"
```

The script reads `installed.json` and `templates/VERSION`, compares modules, and outputs JSON.

Parse the JSON output. Handle errors:

- **Bash call fails** (no network, git clone fails):
  ```
  Unable to reach GitHub.

  Manual upgrade:
    cd /path/to/claude-code-setup
    git pull
    ./install.sh --update
  ```
  Stop here.

- **JSON has `"error": "not_installed"`** (no installed.json):
  ```
  claude-code-setup is not installed. Run install.sh first.
  ```
  Clean up: `rm -rf "$temp"` → Stop.

- **Success**: Parse JSON fields. The `temp_dir` field contains the repo path. Continue to Phase 2.

### JSON structure reference

```json
{
  "temp_dir": "/tmp/claude-setup-XXXXXX",
  "base": { "installed": 50, "available": 52, "update_available": true },
  "custom": { "configured": true, "installed": 1, "available": 2, "update_available": true },
  "new_modules": { "skills": ["name"], "mcp": ["name"], "plugins": ["id@marketplace"] },
  "installed_modules": { "skills": ["name"], "mcp": ["name"], "plugins": ["id@marketplace"] },
  "agent_teams": { "enabled": true }
}
```

## Phase 2: Present + Ask (0 Bash calls)

### Show status

Present a summary from the JSON:

```
claude-code-setup status:
- Base: v{base.installed} installed, v{base.available} available
- Custom: v{custom.installed} installed, v{custom.available} available
- Agent Teams: enabled / not configured

Modules available to install:
  Skills: {new_modules.skills}
  MCP Servers: {new_modules.mcp}
  External Plugins: {new_modules.plugins}
```

Version line variants:
- Update available: `v50 installed, v52 available`
- Up-to-date: `v52 (up-to-date)`
- Custom not configured: `(not configured)` — add tip: `Use /add-custom <url> to add company modules.`

Agent Teams line:
- `Agent Teams: enabled` if `agent_teams.enabled == true`
- `Agent Teams: not configured` if `agent_teams.enabled == false`

If no new modules in any category: `All modules installed.`

### Read CHANGELOG (if upgrade available)

If `base.update_available` is true, use the Read tool on `{temp_dir}/CHANGELOG.md`.
Show relevant entries from content_version `base.installed` to `base.available`.

### Check for new modules that require API keys

For each MCP in `new_modules.mcp`, read `{temp_dir}/mcp/{name}.json` using the Read tool.
Check `requiresApiKey` field. Note which MCPs need API keys for Phase 3 handling.

### AskUserQuestion (multiSelect: true)

Build options dynamically from JSON. Only include options where the condition is met:

| Condition | Option label |
|-----------|-------------|
| `base.update_available == true` | "Upgrade base (vX → vY)" |
| `custom.update_available == true` | "Upgrade custom (vX → vY)" |
| `new_modules.skills` or `new_modules.mcp` has entries | "Install new skills/MCP" |
| `new_modules.plugins` has entries | "Install plugins" |
| any `installed_modules` array is non-empty | "Remove modules" |
| `agent_teams.enabled == false` | "Enable Agent Teams" |

If everything is up-to-date, no new modules, and Agent Teams already configured:
→ Show `All up-to-date.` → Clean up with a Bash call: `rm -rf "$temp"`
   (This path uses 2 prompts total: 1 discover + 1 cleanup. No Phase 3.)

### Follow-up questions

**If user selected "Install new skills/MCP":**
→ Second AskUserQuestion (multiSelect) listing each module from `new_modules.skills` and `new_modules.mcp`.

**If user selected "Remove modules":**
→ Second AskUserQuestion (multiSelect) listing installed modules from `installed_modules.skills`, `installed_modules.mcp`, and `installed_modules.plugins`.

**If user selected "Install plugins":**
→ Second AskUserQuestion (multiSelect) listing each plugin from `new_modules.plugins`.

## Phase 3: Execute (1 Bash call)

Build ONE chained Bash command from all user selections. **Cleanup always uses `;`** (ensures temp dir is removed even if a command in the chain fails).

### Execution chains

| Action | Command segment |
|--------|----------------|
| Upgrade base | `cd "$temp" && ./install.sh --update --yes` |
| Upgrade custom | `git -C ~/.claude/custom pull && new_v=$(cat ~/.claude/custom/VERSION 2>/dev/null \|\| echo "0") && jq --arg v "$new_v" '.custom_version = ($v \| tonumber)' ~/.claude/installed.json > ~/.claude/installed.json.tmp && mv ~/.claude/installed.json.tmp ~/.claude/installed.json` |
| Install skill | `cd "$temp" && ./install.sh --add-skill <name>` |
| Install MCP (no API key) | `cd "$temp" && ./install.sh --add-mcp <name>` |
| Install MCP (API key) | See "MCP with API key" section below |
| Install plugin | `claude plugin marketplace add <repo> 2>/dev/null; claude plugin install <id>@<marketplace> && jq --arg p "<id>@<marketplace>" '.external_plugins = ((.external_plugins // []) + [$p] \| unique)' ~/.claude/installed.json > ~/.claude/installed.json.tmp && mv ~/.claude/installed.json.tmp ~/.claude/installed.json` |
| Remove skill | `cd "$temp" && ./install.sh --remove-skill <name>` |
| Remove MCP | `cd "$temp" && ./install.sh --remove-mcp <name>` |
| Remove plugin | `claude plugin remove <id> && jq '.external_plugins = (.external_plugins // [] \| map(select(. != "<id>@<marketplace>")))' ~/.claude/installed.json > ~/.claude/installed.json.tmp && mv ~/.claude/installed.json.tmp ~/.claude/installed.json` |
| Enable Agent Teams | `[[ -f ~/.claude/settings.json ]] \|\| echo '{}' > ~/.claude/settings.json; jq '.env = (.env // {}) \| .env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"' ~/.claude/settings.json > ~/.claude/settings.json.tmp && mv ~/.claude/settings.json.tmp ~/.claude/settings.json` |
| **Cleanup** (always last) | `; rm -rf "$temp"` |

### Combining actions

Chain selected actions with `&&`, always end with `; rm -rf "$temp"`:

```bash
cd "$temp" && ./install.sh --update --yes && ./install.sh --add-skill standards-kotlin && ./install.sh --remove-mcp brave-search ; rm -rf "$temp"
```

More examples:

| User selections | Full chain |
|-----------------|------------|
| Upgrade base only | `cd "$temp" && ./install.sh --update --yes ; rm -rf "$temp"` |
| Install skill + remove MCP | `cd "$temp" && ./install.sh --add-skill X && ./install.sh --remove-mcp Y ; rm -rf "$temp"` |
| Enable Agent Teams only | `[[ -f ~/.claude/settings.json ]] \|\| echo '{}' > ~/.claude/settings.json; jq '.env = (.env // {}) \| .env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"' ~/.claude/settings.json > ~/.claude/settings.json.tmp && mv ~/.claude/settings.json.tmp ~/.claude/settings.json ; rm -rf "$temp"` |
| Upgrade + install + remove | `cd "$temp" && ./install.sh --update --yes && ./install.sh --add-skill X && ./install.sh --remove-skill Y ; rm -rf "$temp"` |

### MCP with API key (special handling)

When an MCP has `requiresApiKey: true` in its config file (checked in Phase 2):

1. Read the MCP config JSON from `{temp_dir}/mcp/<name>.json`
2. Build a jq command that inserts the config into `~/.claude.json` with `YOUR_API_KEY_HERE` replacing all `{{PLACEHOLDER}}` values
3. Track in installed.json in the same chain
4. After execution, use the Edit tool to add the MCP to the MCP_TABLE in `~/.claude/CLAUDE.md`

Example for brave-search (single API key):
```bash
jq '.mcpServers["brave-search"] = {"type":"stdio","command":"npx","args":["-y","@brave/brave-search-mcp-server"],"env":{"BRAVE_API_KEY":"YOUR_API_KEY_HERE"}}' ~/.claude.json > ~/.claude.json.tmp && mv ~/.claude.json.tmp ~/.claude.json && jq '.mcp = ((.mcp // []) + ["brave-search"] | unique)' ~/.claude/installed.json > ~/.claude/installed.json.tmp && mv ~/.claude/installed.json.tmp ~/.claude/installed.json
```

For MCPs with multiple API keys (e.g., google-search with `GOOGLE_API_KEY` and `GOOGLE_CSE_ID`), replace ALL `{{PLACEHOLDER}}` values with `YOUR_API_KEY_HERE` (or distinct placeholders like `YOUR_GOOGLE_API_KEY_HERE`), and list each key the user needs to replace in the post-execution message.

Show instructions after execution:
```
MCP "brave-search" configured with placeholder.

Replace YOUR_API_KEY_HERE in ~/.claude.json with your actual key.

To get your API key:
{apiKeyInstructions from the MCP config JSON}
```

Note: Since this bypasses install.sh, the MCP_TABLE in `~/.claude/CLAUDE.md` is NOT automatically updated. After the Bash call completes, use the Edit tool to add the MCP entry to the MCP_TABLE section. This is a tool call (not Bash), so it does not add a permission prompt.

### Plugin install details

Get marketplace repo from `{temp_dir}/external-plugins.json`:
```bash
# Read from external-plugins.json (already in cloned repo)
repo=$(jq -r --arg m "<marketplace>" '.marketplaces[$m].repo' "$temp/external-plugins.json")
```

Chain: marketplace add (idempotent) → plugin install → tracking update.

### After execution

Show summary of completed actions.

If anything was installed, upgraded, removed, or Agent Teams was enabled:
```
⚠️  IMPORTANT: Restart Claude Code now.
    After restart, run /catchup to reload context.
```

## IMPORTANT

- **Phase 1 = 1 Bash call** — clone + setup-status.sh
- **Phase 2 = 0 Bash calls** — parse JSON + show status + AskUserQuestion
- **Phase 3 = 1 Bash call** — all operations chained + cleanup
- **Always ask before acting** — never auto-upgrade
- **Cleanup uses `;`** — temp dir removed even if chain fails
- **MCP with API keys** — insert placeholder via jq, don't use --add-mcp (it prompts interactively)

## Output Examples

### Status with upgrade available:
```
claude-code-setup status:
- Base: v50 installed, v52 available
- Custom: v1 (up-to-date)
- Agent Teams: enabled

Modules available to install:
  Skills: standards-kotlin
  MCP Servers: brave-search
  External Plugins: document-skills

Changes in v51-v52:
- v52: Add /skill-creator command skill
- v51: Add standards-kotlin coding standards
```

### All up-to-date:
```
claude-code-setup status:
- Base: v52 (up-to-date)
- Custom: v2 (up-to-date)
- Agent Teams: enabled

All modules installed.
```

### No custom repo:
```
claude-code-setup status:
- Base: v52 (up-to-date)
- Custom: (not configured)
- Agent Teams: not configured

Modules available to install:
  Skills: standards-kotlin

Tip: Use /add-custom <url> to add company modules.
```

### After upgrade + install:
```
Completed:
- Upgraded base: v50 → v52
- Installed skill: standards-kotlin
- Enabled Agent Teams

⚠️  IMPORTANT: Restart Claude Code now.
    After restart, run /catchup to reload context.
```

### MCP with API key:
```
MCP "brave-search" configured with placeholder.

Replace YOUR_API_KEY_HERE in ~/.claude.json with your actual key.

To get your API key:
1. Visit: https://brave.com/search/api/
2. Sign up for 'Data for AI' plan
3. Create an API key (free tier: 2000 queries/month)

⚠️  IMPORTANT: Restart Claude Code now.
    After restart, run /catchup to reload context.
```

### Error:
```
Unable to reach GitHub.

Manual upgrade:
  cd /path/to/claude-code-setup
  git pull
  ./install.sh --update
```

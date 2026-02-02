# Claude Code Setup

Manage your claude-code-setup installation: check status, upgrade, and install modules.

## Tasks

### Phase 1: Check Status

1. **Check current version**
   - Read `content_version` from `~/.claude/installed.json`
   - If file doesn't exist, inform user to run install.sh first

2. **Fetch latest version**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/b33eep/claude-code-setup/main/templates/VERSION
   ```

3. **Clone repo to temp** (needed for module discovery)
   ```bash
   temp_dir=$(mktemp -d /tmp/claude-setup-XXXXXX)
   git clone --depth 1 https://github.com/b33eep/claude-code-setup.git "$temp_dir"
   ```

4. **Discover available modules**
   ```bash
   # Available skills
   ls -1 "$temp_dir/skills/"

   # Available MCP servers
   ls -1 "$temp_dir/mcp/"

   # Available external plugins
   jq -r '.plugins[].id' "$temp_dir/external-plugins.json"
   ```

5. **Get installed modules**
   ```bash
   jq -r '.skills[]' ~/.claude/installed.json 2>/dev/null || echo "(none)"
   jq -r '.mcp[]' ~/.claude/installed.json 2>/dev/null || echo "(none)"
   jq -r '.external_plugins[]' ~/.claude/installed.json 2>/dev/null || echo "(none)"

   # Also check what plugins are actually installed via claude CLI
   claude plugin list 2>/dev/null || echo "(claude CLI not available)"
   ```

6. **Check for new modules** and compare versions
   - Find modules NOT in installed.json (delta)
   - Determine if upgrade is needed (current < latest)
   - Fetch CHANGELOG.md from GitHub to show changes

7. **Check custom repo** (if exists)
   - If `~/.claude/custom` exists:
     ```bash
     # Fetch latest from remote
     git -C ~/.claude/custom fetch origin 2>/dev/null

     # Get local VERSION
     local_version=$(cat ~/.claude/custom/VERSION 2>/dev/null || echo "0")

     # Get remote VERSION
     remote_version=$(git -C ~/.claude/custom show origin/main:VERSION 2>/dev/null || echo "0")
     ```
   - Compare local vs remote VERSION
   - If remote > local: custom update available
   - Read `custom_version` from installed.json for comparison
   - List uninstalled custom modules (custom:* not in installed.json)

### Phase 2: Show Status & Ask User

8. **Present findings to user**

   Show a summary like this:
   ```
   claude-code-setup status:
   - Base: v8 installed, v9 available
   - Custom: v1 installed, v2 available

   Modules available to install:
     Skills:
     - skill-creator (Create custom skills)
     - custom:standards-java (Java standards)

     MCP Servers:
     - brave-search (Web search via Brave)

     External Plugins:
     - code-review-ai (AI-powered architectural review)

   What would you like to do?
   ```

9. **STOP and ask user** (use AskUserQuestion tool)

   Options depend on what's available:
   - "Upgrade base" (if base update available)
   - "Upgrade custom" (if custom update available)
   - "Install modules" (if uninstalled modules exist)
   - "Nothing"

   Combine options as appropriate (e.g., "Upgrade base + custom + install modules")

### Phase 3: Execute User's Choice

10. **Perform base upgrade** (if requested)
    ```bash
    cd "$temp_dir" && ./install.sh --update --yes
    ```

11. **Perform custom upgrade** (if requested)
    ```bash
    git -C ~/.claude/custom pull
    # Update custom_version in installed.json
    if [[ -f ~/.claude/custom/VERSION ]] && [[ -f ~/.claude/installed.json ]]; then
        new_version=$(cat ~/.claude/custom/VERSION 2>/dev/null || echo "0")
        jq --arg v "$new_version" '.custom_version = ($v | tonumber)' \
           ~/.claude/installed.json > tmp && mv tmp ~/.claude/installed.json
    fi
    ```

12. **Install new modules** (if requested)
    - Ask which specific modules to install
    - For Skills and MCP servers, run install.sh --add with appropriate input:
      ```bash
      # Example: Install skill at position 2, no MCP
      printf 'none\n2\nn\n' | "$temp_dir/install.sh" --add
      ```

13. **Install external plugins** (if requested)
    External plugins CANNOT be installed via install.sh --add (stdin issues).
    Install them directly via claude CLI:

    ```bash
    # 1. Get plugin info from external-plugins.json
    plugin_id="code-review-ai"
    marketplace=$(jq -r --arg id "$plugin_id" '.plugins[] | select(.id == $id) | .marketplace' "$temp_dir/external-plugins.json")
    repo=$(jq -r --arg m "$marketplace" '.marketplaces[$m].repo' "$temp_dir/external-plugins.json")

    # 2. Add marketplace (if not already registered)
    if ! claude plugin marketplace list 2>/dev/null | grep -q "❯ $marketplace"; then
        claude plugin marketplace add "$repo"
    fi

    # 3. Install the plugin
    claude plugin install "$plugin_id@$marketplace"

    # 4. Track in installed.json
    jq --arg p "$plugin_id@$marketplace" '.external_plugins = ((.external_plugins // []) + [$p] | unique)' \
       ~/.claude/installed.json > tmp && mv tmp ~/.claude/installed.json
    ```

14. **Cleanup**
    ```bash
    rm -rf "$temp_dir"
    ```

## IMPORTANT

- **Always clone first** - needed to discover available modules
- **Always ask user before taking action** - never auto-upgrade without consent
- **Cleanup LAST** - only after all operations complete

## Output Examples

### Status presentation (before asking):
```
claude-code-setup status:
- Base: v8 installed, v9 available
- Custom: v1 (up-to-date)

Modules available to install:
  Skills:
  - skill-creator (Create custom skills)

  MCP Servers:
  (all installed)

  External Plugins:
  - code-review-ai (AI-powered architectural review)
```

### After upgrade:
```
Upgraded:
- Base: v8 → v9
- Custom: v1 → v2

Changes (base):
- v9: Add /skill-creator command skill

Changes (custom):
- v2: Add standards-kotlin skill

Run /catchup to reload context.
```

### MCP with API key (manual step required):

If an MCP server requires an API key, the install.sh script cannot set it non-interactively.
Show the user how to add it manually:

```
Note: MCP "mcp-name" requires an API key.

To configure manually, add to ~/.claude.json under "mcpServers":

  "mcp-name": {
    "type": "http",
    "url": "https://...",
    "headers": {
      "Authorization": "Bearer YOUR_API_KEY_HERE"
    }
  }

Then restart Claude Code.
```

To get the exact config, read the MCP JSON file from `~/.claude/custom/mcp/<name>.json` and show the user the `config` field with placeholders replaced.

### Already current, modules available to install:
```
claude-code-setup status:
- Base: v9 (up-to-date)
- Custom: v2 (up-to-date)

Modules available to install:
  Skills:
  - custom:standards-kotlin (Kotlin standards)

  MCP Servers:
  - brave-search (Web search via Brave)

  External Plugins:
  - code-review-ai (AI-powered architectural review)

Would you like to install any modules?
```

### After plugin installation:
```
Installing external plugin code-review-ai...
  Adding marketplace claude-code-workflows...
  ✓ Marketplace claude-code-workflows added
  Installing code-review-ai...
  ✓ code-review-ai installed

Restart Claude Code to activate the plugin.
```

### Already current, all modules installed:
```
claude-code-setup status:
- Base: v9 (up-to-date)
- Custom: v2 (up-to-date)

All available modules are installed.
```

### No custom repo configured:
```
claude-code-setup status:
- Base: v9 (up-to-date)
- Custom: (not configured)

All available modules are installed.

Tip: Use /add-custom <url> to add company modules.
```

### Error:
```
Upgrade failed: {reason}

Manual upgrade:
  cd /path/to/claude-code-setup
  git pull
  ./install.sh --update
```

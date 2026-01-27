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
   ```

5. **Get installed modules**
   ```bash
   jq -r '.skills[]' ~/.claude/installed.json 2>/dev/null || echo "(none)"
   jq -r '.mcp[]' ~/.claude/installed.json 2>/dev/null || echo "(none)"
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
    - Run install.sh --add with appropriate input:
      ```bash
      # Example: Install skill at position 2, no MCP
      printf 'none\n2\nn\n' | "$temp_dir/install.sh" --add
      ```

13. **Cleanup**
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

Would you like to install any modules?
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

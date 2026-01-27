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

### Phase 2: Show Status & Ask User

7. **Present findings to user**

   Show a summary like this:
   ```
   claude-code-setup status:
   - Installed: v8
   - Available: v9

   Modules available to install:
     Skills:
     - skill-creator (Create custom skills)
     - standards-javascript (JS/Node.js standards)

     MCP Servers:
     - brave-search (Web search via Brave)

   What would you like to do?
   ```

8. **STOP and ask user** (use AskUserQuestion tool)

   If upgrade available AND uninstalled modules:
   - Options: "Upgrade + install modules", "Upgrade only", "Install modules only", "Nothing"

   If upgrade available, NO uninstalled modules:
   - Options: "Upgrade", "Nothing"

   If already up-to-date AND uninstalled modules:
   - Options: "Install modules", "Nothing"

   If already up-to-date, NO uninstalled modules:
   - Just report: "Up-to-date (v{version}), all modules installed."

### Phase 3: Execute User's Choice

9. **Perform upgrade** (if requested)
   ```bash
   cd "$temp_dir" && ./install.sh --update --yes
   ```

10. **Install new modules** (if requested)
    - Ask which specific modules to install
    - Run install.sh --add with appropriate input:
      ```bash
      # Example: Install skill at position 2, no MCP
      printf 'none\n2\nn\n' | "$temp_dir/install.sh" --add
      ```

11. **Cleanup**
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
- Installed: v8
- Available: v9

Modules available to install:
  Skills:
  - skill-creator (Create custom skills)

  MCP Servers:
  (all installed)
```

### After upgrade:
```
Upgraded claude-code-setup: v8 → v9

Changes:
- v9: Add /skill-creator command skill

Run /catchup to reload context.
```

### Already current, modules available to install:
```
claude-code-setup status:
- Version: v9 (up-to-date)

Modules available to install:
  Skills:
  - standards-javascript (JS/Node.js standards)

  MCP Servers:
  - brave-search (Web search via Brave)

Would you like to install any modules?
```

### Already current, all modules installed:
```
claude-code-setup is up-to-date (v9)
All available modules are installed.
```

### Error:
```
Upgrade failed: {reason}

Manual upgrade:
  cd /path/to/claude-code-setup
  git pull
  ./install.sh --update
```

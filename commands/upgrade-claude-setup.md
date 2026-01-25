# Upgrade Claude Setup

Update claude-code-setup to the latest version without leaving Claude Code.

## Tasks

1. **Check current version**
   - Read `content_version` from `~/.claude/installed.json`
   - If file doesn't exist, inform user to run install.sh first

2. **Fetch latest version**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/b33eep/claude-code-setup/main/templates/VERSION
   ```

3. **Compare versions**
   - If current >= latest: "You're up-to-date (v{version})" then proceed to step 6 (check new modules)
   - If current < latest: proceed with upgrade

4. **Perform upgrade**
   ```bash
   # Clone to temp directory
   temp_dir=$(mktemp -d)
   git clone --depth 1 https://github.com/b33eep/claude-code-setup.git "$temp_dir"

   # Run update (--yes skips confirmation prompts)
   cd "$temp_dir" && ./install.sh --update --yes

   # Keep temp_dir for step 6, cleanup after
   ```

5. **Report changes**
   - Fetch CHANGELOG.md from GitHub
   - Show changes between old and new version
   - Summarize what was updated

6. **Check for new modules**
   - List available modules from cloned repo:
     ```bash
     # Skills
     ls -1 "$temp_dir/skills/"

     # MCP servers
     ls -1 "$temp_dir/mcp/"
     ```
   - Read installed modules from `~/.claude/installed.json`:
     ```bash
     jq -r '.skills[]' ~/.claude/installed.json
     jq -r '.mcp[]' ~/.claude/installed.json
     ```
   - Compare and find not-yet-installed modules
   - If new modules available: Ask user which to install

7. **Install new modules (if requested)**
   - For each requested module, run install.sh --add with appropriate input
   - Skills and MCP use numbered selection in install.sh --add
   - Use printf to provide input, e.g.:
     ```bash
     # Install skill at position 2, no MCP
     printf 'none\n2\nn\n' | "$temp_dir/install.sh" --add
     ```

8. **Cleanup**
   ```bash
   rm -rf "$temp_dir"
   ```

## Output

Success with new modules:
```
Upgraded claude-code-setup: v{old} -> v{new}

Changes:
- {change 1}
- {change 2}

New modules available:
  Skills:
  - standards-javascript (JS/Node.js coding standards)

  MCP Servers:
  - brave-search (Web search)

Install any of these? (list names or 'none')
```

Success, no new modules:
```
Upgraded claude-code-setup: v{old} -> v{new}

Changes:
- {change 1}

All available modules already installed.
Run /catchup to reload context.
```

Already current:
```
claude-code-setup is up-to-date (v{version})
```

Already current but new modules:
```
claude-code-setup is up-to-date (v{version})

New modules available:
  - standards-javascript

Install? (list names or 'none')
```

Error:
```
Upgrade failed: {reason}

Manual upgrade:
  cd /path/to/claude-code-setup
  git pull
  ./install.sh --update
```

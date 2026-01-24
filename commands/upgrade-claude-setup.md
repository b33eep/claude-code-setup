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
   - If current >= latest: "You're up-to-date (v{version})"
   - If current < latest: proceed with upgrade

4. **Perform upgrade**
   ```bash
   # Clone to temp directory
   temp_dir=$(mktemp -d)
   git clone --depth 1 https://github.com/b33eep/claude-code-setup.git "$temp_dir"

   # Run update
   cd "$temp_dir" && ./install.sh --update

   # Cleanup
   rm -rf "$temp_dir"
   ```

5. **Report changes**
   - Fetch CHANGELOG.md from GitHub
   - Show changes between old and new version
   - Summarize what was updated

## Output

Success:
```
Upgraded claude-code-setup: v{old} -> v{new}

Changes:
- {change 1}
- {change 2}

Run /catchup to reload context.
```

Already current:
```
claude-code-setup is up-to-date (v{version})
```

Error:
```
Upgrade failed: {reason}

Manual upgrade:
  cd /path/to/claude-code-setup
  git pull
  ./install.sh --update
```

# Remove Custom Modules

Remove the active custom module repository and all its installed artifacts
(skills, MCP servers, command overrides, scripts) from claude-code-setup.

Zero residue: deletes the git clone at `~/.claude/custom/`, every installed
copy, and every tracking entry; restores base versions for commands that
overrode a base command.

Only one custom repo can be active at a time, so no URL argument is needed.

## Usage

```
/remove-custom
```

## Tasks

1. **Check installation state**
   - If `~/.claude/installed.json` doesn't exist → output the "no installation"
     message and stop.
   - If `installed.json` has no `custom_url` AND `~/.claude/custom/` doesn't
     exist → output the "nothing to remove" message and stop.

2. **Execute removal** (1 Bash call)

   Clone the latest claude-code-setup, run `--remove-custom`, then clean up:

   ```bash
   temp=$(mktemp -d /tmp/claude-setup-XXXXXX) && \
   git clone --depth 1 https://github.com/b33eep/claude-code-setup.git "$temp" 2>/dev/null && \
   cd "$temp" && ./install.sh --remove-custom ; rm -rf "$temp"
   ```

   The script handles:
   - Removing every `custom:` skill from `~/.claude/skills/` and `installed.json`
   - Removing every `custom:` MCP server from `~/.claude.json` and `installed.json`
   - Deleting every custom command override; restoring base versions when a
     base command exists in the claude-code-setup repo
   - Deleting every custom script from `~/.claude/scripts/`
   - Deleting `~/.claude/custom/` (the git clone)
   - Clearing `custom_url` and `custom_version` from `installed.json`
   - Rebuilding `~/.claude/CLAUDE.md`

3. **Report**
   - Relay the counts printed by `install.sh`.
   - If MCP servers were removed, remind the user to restart Claude Code.

## Output

Success:
```
Removed custom repo: <url>

  - N skill(s)
  - M MCP server(s)
  - K command(s) (base versions restored where available)
  - L script(s)
  - ~/.claude/custom/
  - custom_url, custom_version

CLAUDE.md rebuilt.

IMPORTANT: Restart Claude Code to deactivate removed MCP servers.
```

Nothing to remove:
```
No custom repo registered (~/.claude/installed.json has no custom_url, and
~/.claude/custom/ does not exist). Nothing to remove.
```

No installation:
```
claude-code-setup is not installed. Nothing to remove.
```

Network error (clone failed):
```
Unable to reach GitHub.

Manual removal:
  cd /path/to/claude-code-setup
  ./install.sh --remove-custom
```

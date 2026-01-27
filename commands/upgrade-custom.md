# Upgrade Custom Modules

Update custom module repository to the latest version.

## Tasks

1. **Check if ~/.claude/custom exists**
   - If not: inform user to run `/add-custom <url>` first

2. **Check if it's a git repo**
   - Check for `~/.claude/custom/.git`
   - If not a git repo: warn and abort

3. **Pull latest changes**
   ```bash
   git -C ~/.claude/custom pull
   ```

4. **Update custom_version in installed.json**
   - Read `~/.claude/custom/VERSION` (if exists)
   - Update installed.json:
     ```bash
     # Only if VERSION exists and installed.json exists
     if [[ -f ~/.claude/custom/VERSION ]] && [[ -f ~/.claude/installed.json ]]; then
         new_version=$(cat ~/.claude/custom/VERSION 2>/dev/null || echo "0")
         jq --arg v "$new_version" '.custom_version = ($v | tonumber)' \
            ~/.claude/installed.json > tmp && mv tmp ~/.claude/installed.json
     fi
     ```

5. **Show what changed**
   - Parse git output for files changed
   - Show version change: "Custom version: v1 → v2"
   - Display summary

6. **Hint next step**
   - "Run /claude-code-setup to install new modules"
   - "Run /catchup to reload context"

## Output

Success:
```
Updated custom modules.

Custom version: v1 → v2
Changes:
- 2 files changed

Run /claude-code-setup to install new modules.
Run /catchup to reload context.
```

Already up-to-date:
```
Custom modules are up-to-date (v2).
```

Error (no custom repo):
```
No custom repo found.

Use /add-custom <url> to add a custom module repository first.
```

Error (not a git repo):
```
~/.claude/custom exists but is not a git repository.

To fix:
  rm -rf ~/.claude/custom
  /add-custom <url>
```

Error (pull failed):
```
Failed to update custom modules: {error}

Manual update:
  cd ~/.claude/custom
  git pull
```

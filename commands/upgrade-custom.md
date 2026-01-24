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

4. **Show what changed**
   - Parse git output for files changed
   - Display summary

5. **Hint next step**
   - "Run /catchup to reload context"

## Output

Success:
```
Updated custom modules.

Changes:
- 2 files changed

Run /catchup to reload context.
```

Already up-to-date:
```
Custom modules are up-to-date.
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

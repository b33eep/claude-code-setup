# Add Custom Modules

Add a custom module repository (company or personal) to claude-code-setup.

## Usage

```
/add-custom <git-url>
```

## Tasks

1. **Validate URL format**
   - Accept: `git@...` or `https://...`
   - Reject: plain `http://` (insecure)
   - If invalid, show error and expected formats

2. **Check if ~/.claude/custom already exists**
   - If exists and is a git repo:
     - Get current remote: `git -C ~/.claude/custom remote get-url origin`
     - If same URL: skip clone, run `git pull` instead
     - If different URL: warn and abort
   - If exists but NOT a git repo: warn and abort
   - If doesn't exist: proceed with clone

3. **Clone repository**
   ```bash
   git clone <url> ~/.claude/custom
   ```

4. **Read VERSION and update installed.json**
   - Read `~/.claude/custom/VERSION` (if exists)
   - Update `~/.claude/installed.json`:
     ```bash
     # Only if VERSION exists and installed.json exists
     if [[ -f ~/.claude/custom/VERSION ]] && [[ -f ~/.claude/installed.json ]]; then
         version=$(cat ~/.claude/custom/VERSION 2>/dev/null || echo "0")
         jq --arg v "$version" --arg u "<url>" \
            '.custom_version = ($v | tonumber) | .custom_url = $u' \
            ~/.claude/installed.json > tmp && mv tmp ~/.claude/installed.json
     fi
     ```
   - If VERSION doesn't exist, skip (legacy custom repo without versioning)

5. **Show available modules**
   - Count skills in `~/.claude/custom/skills/`
   - Count MCP servers in `~/.claude/custom/mcp/`
   - Display: "Found X skills, Y MCP servers"
   - Display: "Custom version: vX" (if VERSION exists)

6. **Hint next step**
   - "Run /claude-code-setup to select and install modules"

## Output

Success (new clone):
```
Cloned custom modules from <url>

Custom version: v1
Found:
- 3 skills
- 2 MCP servers

Run /claude-code-setup to select and install modules.
```

Success (existing, pulled):
```
Custom repo already configured. Pulled latest changes.

Custom version: v2 (was v1)
Found:
- 3 skills
- 2 MCP servers

Run /claude-code-setup to install new modules.
```

Error (different repo exists):
```
~/.claude/custom already exists with a different repository:
  Current: git@other-company.com:repo.git
  Requested: <url>

To switch repositories:
  rm -rf ~/.claude/custom
  /add-custom <url>
```

Error (not a git repo):
```
~/.claude/custom exists but is not a git repository.

To fix:
  rm -rf ~/.claude/custom
  /add-custom <url>
```

Error (auth failure):
```
Clone failed: Permission denied (publickey).

Your SSH key isn't configured for this repo.
Contact your admin or check your SSH setup.
```

Error (insecure URL):
```
Insecure URL rejected: http:// is not allowed.

Use HTTPS instead:
  https://github.com/company/repo.git
```

Error (invalid URL):
```
Invalid Git URL. Expected format:
  - git@company.com:team/repo.git
  - https://github.com/company/repo.git
```

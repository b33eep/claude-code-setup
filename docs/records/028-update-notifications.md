# Record 028: Update Notifications

## Status

Done (Content v33)

## Problem

Users don't know when new content versions are available. Currently:
- `installed.json` tracks installed version
- `templates/VERSION` contains current version
- `/claude-code-setup` shows delta when run manually

But users must actively run `/claude-code-setup` to discover updates. This leads to:
- Missing new features/fixes
- Running outdated workflows
- No awareness of improvements

## Constraints

- **No spam**: Don't interrupt every session
- **No slowdown**: Don't block workflow with mandatory checks
- **Non-intrusive**: Information should be available, not forced
- **No permission prompts**: Must work without Claude tool permissions

## Options

### Option A: Passive indicator in ccstatusline

Add version info to `ccstatusline` output when outdated:

```
ccstatusline: project:my-app | skills:python,shell | update:v29
```

- Pro: Zero interruption, always visible
- Pro: User decides when to act
- Con: Easy to miss/ignore
- Con: Requires network check or local VERSION comparison

### Option B: One-time hint per session

At session start (after `/catchup`), show hint if outdated:

```
Hint: claude-code-setup v29 available (you have v28). Run /claude-code-setup to update.
```

- Pro: Visible but not blocking
- Pro: Only once per session
- Con: Adds noise to session start
- Con: Requires version check mechanism

### Option C: Integrate into /catchup

Add version check to `/catchup` output:

```
## Catchup Summary
...
### Updates Available
- claude-code-setup: v28 → v29 (run /claude-code-setup)
```

- Pro: Natural integration point
- Pro: Already reading files anyway
- Con: Makes /catchup slower if network check needed

### Option D: Local VERSION file comparison only

Compare `~/.claude/installed.json` version with bundled VERSION in repo (for git-cloned users) or skip for curl-installed users.

- Pro: No network needed
- Pro: Works offline
- Con: Only works for git clone users
- Con: Curl users would need different mechanism

### Option E: GitHub release check (curl users)

For curl-installed users, optionally check GitHub releases API:

```bash
curl -s https://api.github.com/repos/b33eep/claude-code-setup/releases/latest
```

- Pro: Works for curl users
- Pro: Can cache result (check once per day)
- Con: Requires network
- Con: Privacy consideration (GitHub sees IP)
- Con: Rate limiting

## Decision

**SessionStart Hook with Shell Script**

### Rejected Approaches

| Approach | Problem |
|----------|---------|
| Read Tool in /catchup | Requires Allow-Prompt for ~/.claude/ |
| Bash/jq in /catchup | Requires Allow-Prompt for ~/.claude/ |
| UserPromptSubmit Hook | Runs on every message - too frequent |

**Finding (2026-02-03):** Both Read Tool and Bash commands on `~/.claude/` require user permission. Hooks, however, run as shell commands outside of Claude's permission system.

### Chosen Approach: SessionStart Hook

Claude Code provides a `SessionStart` hook that runs at session start. It can be filtered with matchers:

| Matcher | When |
|---------|------|
| `startup` | New session |
| `resume` | Session resumed |
| `clear` | After /clear |
| `compact` | After compaction |

**Hook Configuration** (`~/.claude/settings.json`):

```json
{
  "hooks": {
    "SessionStart": [{
      "matcher": "startup|clear",
      "hooks": [{
        "type": "command",
        "command": "~/.claude/hooks/check-update.sh"
      }]
    }]
  }
}
```

**Hook Script** (`~/.claude/hooks/check-update.sh`):

```bash
#!/bin/bash
set -euo pipefail

installed_json="$HOME/.claude/installed.json"
remote_url="https://raw.githubusercontent.com/b33eep/claude-code-setup/main/templates/VERSION"

# Skip if installed.json doesn't exist (not installed via claude-code-setup)
[[ -f "$installed_json" ]] || exit 0

# === Base repo check (curl to GitHub raw) ===
local_ver=$(jq -r '.content_version // empty' "$installed_json" 2>/dev/null) || true
if [[ -n "$local_ver" ]]; then
    remote_ver=$(curl -fsSL --max-time 2 "$remote_url" 2>/dev/null) || true
    if [[ -n "$remote_ver" && "$remote_ver" -gt "$local_ver" ]]; then
        echo "Update available: v$local_ver → v$remote_ver (run /claude-code-setup)"
    fi
fi

# === Custom repo check (git ls-remote, no fetch needed) ===
custom_dir="$HOME/.claude/custom"
if [[ -d "$custom_dir/.git" ]]; then
    local_hash=$(git -C "$custom_dir" rev-parse HEAD 2>/dev/null) || true
    remote_hash=$(git -C "$custom_dir" ls-remote --quiet origin HEAD 2>/dev/null | cut -f1) || true
    if [[ -n "$local_hash" && -n "$remote_hash" && "$local_hash" != "$remote_hash" ]]; then
        echo "Custom update available (run /claude-code-setup)"
    fi
fi
```

### Advantages

- **No permission prompt**: Hooks run as shell, not via Claude Tools
- **Once per session**: Only on `startup` and `clear`, not on every resume
- **Non-intrusive**: Only one line of output when update available
- **Fail-silent**: On offline or error → no output
- **Fast**: ~100-200ms total (curl + ls-remote in parallel would be even faster)
- **Provider-agnostic**: Custom repo check works with any Git provider (GitHub, GitLab, Bitbucket, on-prem)
- **No fetch needed**: `git ls-remote` only queries refs (~1KB), no object download

### Disadvantages

- Network request at session start (~100-200ms)
- GitHub sees IP for base repo (public raw URL, no API call)
- Custom repo check doesn't show version numbers (only "update available")
- Requires `jq` and `git` (both checked during installation)

## Testing

### Test Scenarios

| Scenario | Local | Remote | Expected Output |
|----------|-------|--------|-----------------|
| Base up-to-date | v32 | v32 | (none) |
| Base update available | v31 | v32 | "Update available: v31 → v32..." |
| Base offline | v32 | (timeout) | (none) |
| No installed.json | - | - | (none) |
| Custom up-to-date | hash-a | hash-a | (none) |
| Custom update available | hash-a | hash-b | "Custom update available..." |
| Custom offline | hash-a | (timeout) | (none) |
| No custom repo | - | - | (none) |

### Test Script

```bash
#!/bin/bash
# tests/scenarios/17-update-notifications.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../helpers.sh"

setup_test_env

# Copy hook script to test environment
mkdir -p "$CLAUDE_DIR/hooks"
cp "$PROJECT_DIR/hooks/check-update.sh" "$CLAUDE_DIR/hooks/"

scenario "Update Notifications Hook"

# Test 1: No installed.json → silent exit
output=$(HOME="$TEST_DIR" bash "$CLAUDE_DIR/hooks/check-update.sh" 2>&1) || true
if [[ -z "$output" ]]; then
    pass "No installed.json → no output"
else
    fail "No installed.json → no output (got: $output)"
fi

# Test 2: Base up-to-date (mock with high version)
echo '{"content_version": 9999}' > "$INSTALLED_FILE"
output=$(HOME="$TEST_DIR" bash "$CLAUDE_DIR/hooks/check-update.sh" 2>&1) || true
if [[ -z "$output" ]]; then
    pass "Base up-to-date → no output"
else
    fail "Base up-to-date → no output (got: $output)"
fi

# Test 3: Base update available (mock curl)
echo '{"content_version": 1}' > "$INSTALLED_FILE"
mkdir -p "$TEST_DIR/bin"
cat > "$TEST_DIR/bin/curl" << 'EOF'
#!/bin/bash
echo "9999"
EOF
chmod +x "$TEST_DIR/bin/curl"
output=$(PATH="$TEST_DIR/bin:$PATH" HOME="$TEST_DIR" bash "$CLAUDE_DIR/hooks/check-update.sh" 2>&1) || true
if [[ "$output" == *"Update available"* && "$output" == *"v1"* && "$output" == *"v9999"* ]]; then
    pass "Base update available → shows hint with versions"
else
    fail "Base update available → shows hint (got: $output)"
fi

# Test 4: Custom repo update available (mock git)
mkdir -p "$CLAUDE_DIR/custom/.git"
cat > "$TEST_DIR/bin/git" << 'EOF'
#!/bin/bash
if [[ "$*" == *"rev-parse HEAD"* ]]; then
    echo "aaaa1111"
elif [[ "$*" == *"ls-remote"* ]]; then
    printf "bbbb2222\tHEAD\n"
fi
EOF
chmod +x "$TEST_DIR/bin/git"
output=$(PATH="$TEST_DIR/bin:$PATH" HOME="$TEST_DIR" bash "$CLAUDE_DIR/hooks/check-update.sh" 2>&1) || true
if [[ "$output" == *"Custom update available"* ]]; then
    pass "Custom update available → shows hint"
else
    fail "Custom update available → shows hint (got: $output)"
fi

# Test 5: Custom up-to-date (same hash)
cat > "$TEST_DIR/bin/git" << 'EOF'
#!/bin/bash
if [[ "$*" == *"rev-parse HEAD"* ]]; then
    echo "aaaa1111"
elif [[ "$*" == *"ls-remote"* ]]; then
    printf "aaaa1111\tHEAD\n"
fi
EOF
chmod +x "$TEST_DIR/bin/git"
echo '{"content_version": 9999}' > "$INSTALLED_FILE"  # Reset base to up-to-date
output=$(PATH="$TEST_DIR/bin:$PATH" HOME="$TEST_DIR" bash "$CLAUDE_DIR/hooks/check-update.sh" 2>&1) || true
if [[ -z "$output" ]]; then
    pass "Custom up-to-date → no output"
else
    fail "Custom up-to-date → no output (got: $output)"
fi

cleanup_test_env
print_summary
```

### Running Tests

```bash
# Run all tests including update notifications
./tests/test.sh

# Run only this scenario
./tests/test.sh 17
```

## Implementation

1. Create hook script: `hooks/check-update.sh` (in repo, copied during install)
2. Register hook in `settings.json` (via install.sh)
3. During installation: Ensure `jq` and `git` as dependencies
4. Add test scenario: `tests/scenarios/17-update-notifications.sh`
5. Documentation:
   - Add `website/pages/reference/hooks.mdx` - explain what hooks are, how they work
   - Document the update notification hook specifically
   - Add hooks to the reference section navigation (`_meta.js`)

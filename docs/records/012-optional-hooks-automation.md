# Record 012: Optional Hooks for Workflow Automation

**Status:** Proposed
**Date:** 2025-01-24

## Context

The current workflow requires three manual steps when context gets full:

```
1. /clear-session  → Document status, commit
2. /clear          → Clear context
3. /catchup        → Reload context
```

Users often forget these steps, leading to:
- Auto-compact triggered without documentation
- Lost context
- Frustration

### Research Summary

We investigated several approaches to automate this workflow:

| Approach | Result |
|----------|--------|
| Claude Code Hooks | ✅ SessionStart, PreCompact hooks available |
| SlashCommand Tool | ❌ Not accessible to Claude (cannot run `/clear`) |
| Plugin System | ⚠️ Possible but no advantage over hooks in settings |
| SQLite + AI compression | ❌ Rejected (token costs, opaque, complexity) |

**Key finding:** `/clear` cannot be automated - it requires user input. But we can automate everything else.

## Decision

Add **optional hooks** as an install choice. Users can choose:

| Mode | Behavior | For whom |
|------|----------|----------|
| **Manual** (current) | User runs all 3 commands | Users who want full control |
| **Assisted** (new) | Hooks automate 2 of 3 steps | Users who want less manual work |

Both modes coexist. User chooses during install.

### Assisted Mode Behavior

```
PreCompact (auto) Hook:
  → Updates CLAUDE.md status table
  → Commits changes (if any)
  → Warns user: "Context full. Run /clear to continue."

SessionStart (clear|compact) Hook:
  → Runs catchup logic automatically
  → Loads context skills
  → Injects context summary
```

**User only needs to type `/clear`** - everything else happens automatically.

## Implementation

### 1. Hook Scripts

Create `~/.claude/hooks/` directory with:

```
~/.claude/hooks/
├── pre-compact.sh      # Document + commit + warn
└── session-start.sh    # Catchup logic
```

**pre-compact.sh:**
```bash
#!/bin/bash
set -euo pipefail

# Read input from stdin
input=$(cat)
trigger=$(echo "$input" | jq -r '.trigger // "unknown"')

# Only act on auto-compact
if [[ "$trigger" != "auto" ]]; then
  exit 0
fi

project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
claude_md="$project_dir/CLAUDE.md"

# Update status if CLAUDE.md exists
if [[ -f "$claude_md" ]]; then
  timestamp=$(date '+%Y-%m-%d %H:%M')
  # Could add status update logic here
fi

# Commit if there are changes
if git -C "$project_dir" diff --quiet 2>/dev/null; then
  : # No changes
else
  git -C "$project_dir" add -A
  git -C "$project_dir" commit -m "docs(status): auto-save before context limit" || true
fi

# Warn user (goes to stderr, shown to user)
echo "⚠️  Context limit reached. Changes saved. Run /clear to continue." >&2

exit 0
```

**session-start.sh:**
```bash
#!/bin/bash
set -euo pipefail

input=$(cat)
source=$(echo "$input" | jq -r '.source // "unknown"')

# Only run catchup logic on clear or compact
if [[ "$source" != "clear" && "$source" != "compact" ]]; then
  exit 0
fi

project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Gather context (similar to /catchup)
context=""

# Recent git changes
if git -C "$project_dir" rev-parse --git-dir > /dev/null 2>&1; then
  recent_files=$(git -C "$project_dir" diff --name-only HEAD~5 2>/dev/null | head -10)
  if [[ -n "$recent_files" ]]; then
    context+="Recent changes:\n$recent_files\n\n"
  fi
fi

# Output context (goes to Claude's context via stdout)
if [[ -n "$context" ]]; then
  echo -e "$context"
fi

exit 0
```

### 2. Settings Configuration

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreCompact": [{
      "matcher": "auto",
      "hooks": [{
        "type": "command",
        "command": "~/.claude/hooks/pre-compact.sh",
        "timeout": 30
      }]
    }],
    "SessionStart": [{
      "matcher": "clear|compact",
      "hooks": [{
        "type": "command",
        "command": "~/.claude/hooks/session-start.sh",
        "timeout": 30
      }]
    }]
  }
}
```

### 3. Install Script Changes

Add to `install.sh`:

```bash
configure_hooks() {
  if [[ -n "${YES_FLAG:-}" ]]; then
    return 0  # Skip in non-interactive mode
  fi

  # Check if hooks already configured
  if jq -e '.hooks.PreCompact' ~/.claude/settings.json > /dev/null 2>&1; then
    return 0  # Already configured
  fi

  echo ""
  echo "Workflow automation (hooks):"
  echo "  Manual:   You run /clear-session, /clear, /catchup"
  echo "  Assisted: Hooks automate documentation + catchup"
  echo ""
  read -p "Enable assisted mode? [y/N] " -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    install_hooks
  fi
}

install_hooks() {
  mkdir -p ~/.claude/hooks

  # Copy hook scripts
  cp "$SCRIPT_DIR/hooks/pre-compact.sh" ~/.claude/hooks/
  cp "$SCRIPT_DIR/hooks/session-start.sh" ~/.claude/hooks/
  chmod +x ~/.claude/hooks/*.sh

  # Merge hooks into settings.json
  # ... (jq merge logic)

  echo "✓ Hooks installed (assisted mode)"
}
```

### 4. File Structure

```
claude-code-setup/
├── hooks/                    # NEW
│   ├── pre-compact.sh
│   └── session-start.sh
├── install.sh                # Add configure_hooks()
└── ...

~/.claude/
├── hooks/                    # NEW (if assisted mode)
│   ├── pre-compact.sh
│   └── session-start.sh
├── settings.json             # hooks config added
└── ...
```

## User Experience

### Manual Mode (unchanged)

```
User: *works until context full*
Claude: *auto-compact happens*
User: *loses context, frustrated*
```

### Assisted Mode (new)

```
User: *works until context full*
Hook: *auto-saves, commits, warns*
User: "Oh, I need to /clear"
User: /clear
Hook: *auto-loads context*
User: *continues seamlessly*
```

## Alternatives Considered

| Alternative | Why rejected |
|-------------|--------------|
| **Plugin conversion** | Too much effort, no `/clear` automation anyway |
| **SQLite + AI compression** | Token costs, opaque storage, complexity |
| **Always-on hooks** | Some users want full control |
| **Prompt-based hooks** | Overkill for simple file operations |

## Consequences

### Positive

- Reduces manual steps from 3 to 1
- User chooses their preferred mode
- No breaking changes for existing users
- No token costs (bash scripts only)
- Transparent (scripts are readable)

### Negative

- Two modes to maintain
- Hooks add complexity to settings.json
- Scripts need to handle edge cases
- jq dependency for JSON parsing in scripts

## Testing

| Test | Scenario |
|------|----------|
| Fresh install manual | Choose "N" at hooks prompt, verify no hooks |
| Fresh install assisted | Choose "Y", verify hooks installed |
| Existing user upgrade | Hooks prompt shown, can opt-in |
| PreCompact trigger | Simulate auto-compact, verify commit + warning |
| SessionStart trigger | Run /clear, verify context injected |

## Rollback

Remove hooks:

```bash
# Remove hook scripts
rm -rf ~/.claude/hooks

# Remove from settings.json
jq 'del(.hooks.PreCompact, .hooks.SessionStart)' ~/.claude/settings.json > tmp && mv tmp ~/.claude/settings.json
```

## Open Questions

1. Should `session-start.sh` also load context skills automatically?
2. How to handle projects without git (skip commit)?
3. Should we add a `/toggle-hooks` command to switch modes?

## References

- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)
- [Record 004: Document & Clear Workflow](004-document-and-clear-workflow.md)
- [Record 009: ccstatusline Integration](009-ccstatusline-integration.md)

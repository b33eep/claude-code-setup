# Record 012: Optional Hooks for Workflow Automation

**Status:** Proposed (Validated)
**Date:** 2025-01-24
**Revised:** 2025-01-26

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

### Research Summary (Revised)

We investigated several approaches to automate this workflow:

| Approach | Result |
|----------|--------|
| PreCompact Hook | ❌ Cannot prevent auto-compact, runs too late |
| Stop Hook + Context Monitoring | ✅ Can warn BEFORE auto-compact triggers |
| SessionStart Hook | ✅ Can reload context after clear/compact |
| SlashCommand Tool | ❌ Not accessible to Claude (cannot run `/clear`) |
| SQLite + AI compression | ❌ Rejected (token costs, opaque, complexity) |

**Key findings:**
1. PreCompact hook runs before compact but **cannot prevent it** - compact always follows
2. Auto-compact triggers at ~78% context usage
3. We can calculate context percentage ourselves using `transcript_path` (like ccstatusline does)
4. Stop hook can proactively check context and warn at 70% - **before** auto-compact

## Decision

Add **optional hooks** as an install choice. Users can choose:

| Mode | Behavior | For whom |
|------|----------|----------|
| **Manual** (current) | User runs all 3 commands | Users who want full control |
| **Assisted** (new) | Hooks automate 2 of 3 steps | Users who want less manual work |

Both modes coexist. User chooses during install.

### Assisted Mode Behavior

```
Stop Hook (after each Claude response):
  → Calculates context percentage from transcript
  → At >70%: Updates CLAUDE.md, commits, warns user
  → User has time to /clear before auto-compact at ~78%

SessionStart (clear|compact) Hook:
  → Runs catchup logic automatically
  → Injects context summary (recent changes, status)
```

**User only needs to type `/clear`** - everything else happens automatically.

### What Gets Automated

| Step | Manual Mode | Assisted Mode |
|------|-------------|---------------|
| 1. Monitor context | User must watch | ✅ Hook checks automatically |
| 2. Warn at 70% | - | ✅ Hook warns automatically |
| 3. Commit changes | `/clear-session` manual | ✅ Hook commits automatically |
| 4. Clear context | `/clear` manual | ❌ **User must type /clear** |
| 5. Reload context | `/catchup` manual | ✅ Hook injects automatically |

**Note:** `/clear` cannot be automated - Claude Code doesn't allow hooks to trigger it.

**Improvement:** 3 manual steps → 1 manual step, plus early warning before auto-compact.

## Implementation

### 1. Hook Scripts

Create `~/.claude/hooks/` directory with:

```
~/.claude/hooks/
├── context-monitor.sh   # Check context, save + warn at 70%
└── session-start.sh     # Catchup logic
```

**context-monitor.sh:**
```bash
#!/bin/bash
set -euo pipefail

# Read input from stdin
input=$(cat)
transcript_path=$(echo "$input" | jq -r '.transcript_path // ""')
session_id=$(echo "$input" | jq -r '.session_id // ""')

# Skip if no transcript
if [[ -z "$transcript_path" || ! -f "$transcript_path" ]]; then
  exit 0
fi

# Calculate context length from last assistant message (like ccstatusline)
# Formula: input_tokens + cache_read_input_tokens + cache_creation_input_tokens
context_length=$(tail -200 "$transcript_path" | \
  jq -s '[.[] | select(.type == "assistant") | .message.usage] | last // {} |
  ((.input_tokens // 0) + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0))' \
  2>/dev/null || echo "0")

# Default max tokens (200k for standard models)
# TODO: Could read model from input and adjust for Sonnet 4.5 [1m] (1M tokens)
max_tokens=200000
warning_threshold=70

# Calculate percentage
if [[ "$context_length" -gt 0 ]]; then
  percentage=$((context_length * 100 / max_tokens))
else
  exit 0
fi

# Check if we already warned this session (prevent spam)
warn_file="/tmp/claude-context-warned-${session_id}"
if [[ -z "$session_id" ]] || [[ -f "$warn_file" ]]; then
  exit 0
fi

# Warn at threshold
if [[ $percentage -ge $warning_threshold ]]; then
  project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"

  # Auto-commit if there are changes
  if git -C "$project_dir" rev-parse --git-dir > /dev/null 2>&1; then
    if ! git -C "$project_dir" diff --quiet 2>/dev/null || \
       ! git -C "$project_dir" diff --cached --quiet 2>/dev/null; then
      git -C "$project_dir" add -A 2>/dev/null || true
      git -C "$project_dir" commit -m "docs(status): auto-save at ${percentage}% context" 2>/dev/null || true
    fi
  fi

  # Mark as warned
  touch "$warn_file"

  # Warn user (stderr is shown to user)
  echo "" >&2
  echo "⚠️  Context at ${percentage}% - changes saved." >&2
  echo "   Run /clear to start fresh session." >&2
fi

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
context=""

# Add project CLAUDE.md status if exists
claude_md="$project_dir/CLAUDE.md"
if [[ -f "$claude_md" ]]; then
  # Extract Current Status section
  status=$(sed -n '/^## Current Status/,/^## /p' "$claude_md" | head -30)
  if [[ -n "$status" ]]; then
    context+="## Project Status\n$status\n\n"
  fi
fi

# Recent git changes
if git -C "$project_dir" rev-parse --git-dir > /dev/null 2>&1; then
  recent_files=$(git -C "$project_dir" diff --name-only HEAD~5 2>/dev/null | head -10)
  if [[ -n "$recent_files" ]]; then
    context+="## Recent Changes (last 5 commits)\n$recent_files\n\n"
  fi

  # Uncommitted changes
  uncommitted=$(git -C "$project_dir" status --short 2>/dev/null | head -5)
  if [[ -n "$uncommitted" ]]; then
    context+="## Uncommitted Changes\n$uncommitted\n\n"
  fi
fi

# Output context (stdout goes to Claude's context)
if [[ -n "$context" ]]; then
  echo -e "# Session Resumed - Auto-loaded Context\n"
  echo -e "$context"
  echo -e "---\nRun /catchup for full context reload if needed."
fi

exit 0
```

### 2. Settings Configuration

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "~/.claude/hooks/context-monitor.sh",
        "timeout": 10
      }]
    }],
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "~/.claude/hooks/session-start.sh",
        "timeout": 30
      }]
    }]
  }
}
```

Note: SessionStart hook filters by `source` field inside the script (not via `matcher` which is only for tool hooks).

### 3. Install Script Changes

Add to `install.sh`:

```bash
configure_hooks() {
  if [[ -n "${YES_FLAG:-}" ]]; then
    return 0  # Skip in non-interactive mode
  fi

  # Check if hooks already configured
  if jq -e '.hooks.Stop' ~/.claude/settings.json > /dev/null 2>&1; then
    return 0  # Already configured
  fi

  echo ""
  echo "Workflow automation (hooks):"
  echo "  Manual:   You run /clear-session, /clear, /catchup"
  echo "  Assisted: Hooks monitor context + auto-reload after /clear"
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
  cp "$SCRIPT_DIR/hooks/context-monitor.sh" ~/.claude/hooks/
  cp "$SCRIPT_DIR/hooks/session-start.sh" ~/.claude/hooks/
  chmod +x ~/.claude/hooks/*.sh

  # Merge hooks into settings.json
  local settings_file="$HOME/.claude/settings.json"
  local hooks_config
  hooks_config=$(cat <<'EOF'
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "~/.claude/hooks/context-monitor.sh",
        "timeout": 10
      }]
    }],
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "~/.claude/hooks/session-start.sh",
        "timeout": 30
      }]
    }]
  }
}
EOF
)

  if [[ -f "$settings_file" ]]; then
    jq -s '.[0] * .[1]' "$settings_file" <(echo "$hooks_config") > "${settings_file}.tmp"
    mv "${settings_file}.tmp" "$settings_file"
  else
    echo "$hooks_config" > "$settings_file"
  fi

  echo "✓ Hooks installed (assisted mode)"
}
```

### 4. File Structure

```
claude-code-setup/
├── hooks/                    # NEW
│   ├── context-monitor.sh
│   └── session-start.sh
├── install.sh                # Add configure_hooks()
└── ...

~/.claude/
├── hooks/                    # NEW (if assisted mode)
│   ├── context-monitor.sh
│   └── session-start.sh
├── settings.json             # hooks config added
└── ...
```

## User Experience

### Manual Mode (unchanged)

```
User: *works until context full*
Claude: *auto-compact happens at ~78%*
User: *loses context, frustrated*
```

### Assisted Mode (new)

```
User: *works normally*
Claude: *responds*
Hook: *silently checks context: 45%... 60%... 70%*

[At 70%]
Hook: *auto-commits any changes*
Hook: "⚠️ Context at 70% - changes saved. Run /clear to start fresh session."

User: /clear

Hook: *SessionStart injects context summary*
Claude: "Session resumed. I see recent changes to..."
User: *continues seamlessly*
```

## Context Calculation

Based on ccstatusline's approach:

```
contextLength = input_tokens + cache_read_input_tokens + cache_creation_input_tokens
percentage = (contextLength / maxTokens) * 100
```

| Model | Max Tokens | Warning at 70% |
|-------|------------|----------------|
| Standard (Opus 4, Sonnet 4) | 200,000 | 140,000 |
| Sonnet 4.5 [1m] | 1,000,000 | 700,000 |

## Alternatives Considered

| Alternative | Why rejected |
|-------------|--------------|
| **PreCompact hook** | Cannot prevent auto-compact, too late |
| **PostToolUse hook** | Runs too often, performance overhead |
| **Plugin conversion** | Too much effort, no advantage |
| **SQLite + AI compression** | Token costs, opaque storage, complexity |
| **Always-on hooks** | Some users want full control |

## Consequences

### Positive

- Warns user BEFORE auto-compact (proactive vs reactive)
- Reduces manual steps from 3 to 1
- User chooses their preferred mode
- No breaking changes for existing users
- No token costs (bash scripts only)
- Transparent (scripts are readable)
- Auto-commits preserve work even if user forgets

### Negative

- Two modes to maintain
- Stop hook runs after every response (kept lightweight: ~10ms)
- Hooks add complexity to settings.json
- jq dependency for JSON parsing in scripts

## Testing

| Test | Scenario |
|------|----------|
| Fresh install manual | Choose "N" at hooks prompt, verify no hooks |
| Fresh install assisted | Choose "Y", verify hooks installed |
| Existing user upgrade | Hooks prompt shown, can opt-in |
| Context monitor | Mock transcript at 70%+, verify warning + commit |
| SessionStart trigger | Run /clear, verify context injected |
| No spam | Verify warning only shown once per session |

## Rollback

Remove hooks:

```bash
# Remove hook scripts
rm -rf ~/.claude/hooks

# Remove from settings.json
jq 'del(.hooks.Stop, .hooks.SessionStart)' ~/.claude/settings.json > tmp && mv tmp ~/.claude/settings.json
```

## Open Questions

1. ~~Should `session-start.sh` also load context skills automatically?~~ → No, CLAUDE.md loading triggers skill loading
2. ~~How to handle projects without git?~~ → Skip commit silently
3. Should we detect model and adjust max_tokens for Sonnet 4.5 [1m]?
4. Should warning threshold be configurable (default 70%)?

## References

- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)
- [ccstatusline](https://github.com/sirmalloc/ccstatusline) - Context calculation approach
- [Record 004: Document & Clear Workflow](004-document-and-clear-workflow.md)
- [Record 009: ccstatusline Integration](009-ccstatusline-integration.md)

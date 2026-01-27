# Record 019: Auto-Allow Permissions for /claude-code-setup

**Status:** Done
**Date:** 2026-01-27

## Problem

When running `/claude-code-setup`, Claude Code's sandbox prompts the user for permission on every Bash command (`mktemp`, `git clone`, `curl`, `rm -rf`, etc.). This creates a poor UX — the user must click "Yes" multiple times for routine upgrade operations.

## Solution

During installation, merge allow rules into `~/.claude/settings.json` so the `/claude-code-setup` command can run without permission prompts.

### Allow Rules

```json
{
  "permissions": {
    "allow": [
      "Bash(mktemp -d:*)",
      "Bash(git clone --depth 1:*)",
      "Bash(curl -fsSL:*)",
      "Bash(rm -rf /tmp/claude-setup-:*)",
      "Bash(jq:*)",
      "Bash(ls -1:*)"
    ]
  }
}
```

### Implementation

1. **New lib module:** `lib/permissions.sh` — merges allow rules into `settings.json`
2. **Called from:** `do_install()` in `install.sh` (before statusline config)
3. **Migration:** `run_migrations()` in `lib/update.sh` adds rules for existing users upgrading to v19
4. **Merge strategy:** Read existing `permissions.allow`, add missing rules, write back
5. **Idempotent:** Skip rules that already exist
6. **Deterministic temp path:** `/claude-code-setup` uses `mktemp -d /tmp/claude-setup-XXXXXX` so `rm -rf` rule can be scoped

### Design Decisions

- **Prefix match (`:*`)** over glob — safer, respects word boundaries
- **Specific commands** — not blanket `Bash(git:*)`, only what `/claude-code-setup` needs
- **`rm -rf` scoped to `/tmp/claude-setup-`** — not a general rm allow
- **Merge, not overwrite** — preserves user's existing permission rules
- **Trust model:** `curl -fsSL` and `git clone --depth 1` rules trust that only the hardcoded `/claude-code-setup` command template uses these prefixes. If a user or injected prompt constructs different commands with these prefixes, they pass without prompts. Acceptable trade-off given the commands are not destructive.

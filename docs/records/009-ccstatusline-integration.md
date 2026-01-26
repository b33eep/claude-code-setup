# Record 009: ccstatusline Integration

**Status:** Accepted
**Date:** 2025-01-24

## Context

The `/wrapup` workflow depends on users knowing when context usage is high. Without visibility into context usage, users:

1. Don't know when to run `/wrapup`
2. May hit context limits unexpectedly
3. Miss the opportunity to document before auto-compaction

Claude Code supports custom status lines via `settings.json`, but requires manual configuration through `/config` or direct file editing.

## Decision

### Integrate ccstatusline During Install

- Offer ccstatusline configuration as part of base install (not a separate module)
- Default to "yes" when prompted
- Use [ccstatusline](https://github.com/sirmalloc/ccstatusline) by sirmalloc

### Two Configuration Files

1. **Claude settings** (`~/.claude/settings.json`):
   ```json
   {
     "statusLine": "npx -y ccstatusline@latest"
   }
   ```

2. **ccstatusline config** (`~/.config/ccstatusline/settings.json`):
   - Only created if not exists (respects existing user config)
   - Default widgets: model, tokens, context %, git branch, git changes

### Default Status Line Format

```
Model: Opus 4.5 | Total: 1.4M | Ctx: 43.8k | Ctx: 21.9% | main | (+0,-0)
```

### User Customization

After install, users can customize via:
```bash
npx ccstatusline@latest
```

## Alternatives

| Alternative | Pros | Cons |
|-------------|------|------|
| Built-in Claude status | No third-party dep | Less customizable |
| Manual setup only | Simpler install | Poor discoverability |
| Make it a module | Consistent with MCP/skills | Too small for module overhead |

## Consequences

### Positive

- Context visibility out-of-box
- Supports `/wrapup` workflow (know when to clear)
- Respects existing user config
- Easy customization via npx

### Negative

- Third-party npm dependency (ccstatusline)
- Extra config file (`~/.config/ccstatusline/settings.json`)
- Requires Node.js/npm (already needed for MCP servers)

## Implementation

### Function: configure_statusline()

Added to `install.sh` after skills installation:

1. Check if `statusLine` already configured in `~/.claude/settings.json`
2. Prompt user (default: Y)
3. If yes:
   - Add `statusLine` to Claude settings.json
   - Create default ccstatusline config if not exists

### Skip Conditions

- Already has `statusLine` in settings.json (any value)
- User declines prompt

### Prompt Behavior

The status line prompt defaults to **"Y" (yes)**, unlike other prompts in install.sh which default to "N" (no). This is intentional because:

1. The feature directly supports the core `/wrapup` workflow
2. It's non-destructive (can be disabled anytime)
3. New users benefit most from context visibility

### Update Behavior

The `--update` command does **not** trigger the status line prompt. This is intentional:

- `--update` is for updating existing content, not changing user preferences
- Users who declined during install made a deliberate choice
- Status line can be added later via `--add` or manual configuration

## Rollback

To disable the status line:

1. Remove `statusLine` from `~/.claude/settings.json`:
   ```bash
   jq 'del(.statusLine)' ~/.claude/settings.json > tmp && mv tmp ~/.claude/settings.json
   ```

2. Optionally delete ccstatusline config:
   ```bash
   rm -rf ~/.config/ccstatusline
   ```

## References

- [ccstatusline](https://github.com/sirmalloc/ccstatusline) by sirmalloc
- [Record 004: Document & Clear Workflow](004-document-and-clear-workflow.md)

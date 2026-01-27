# Record 020: Custom Modules Versioning

**Status:** Done
**Date:** 2026-01-27

## Problem

Developers in a company clone custom repos via `/add-custom` and don't maintain them manually. When the team maintainer adds new skills or updates existing ones, developers don't find out automatically.

## Solution

Analog to base versioning:

### Custom Repo Structure

```
claude-code-custom/
├── VERSION              # e.g. "1"
├── CHANGELOG.md         # Documents changes for team
├── skills/
│   └── standards-java/
└── mcp/
```

### installed.json Extension

```json
{
  "content_version": 19,
  "custom_version": 1,      // NEW - optional, only if custom repo exists
  "custom_url": "ssh://...", // NEW - optional, for info
  "mcp": [...],
  "skills": [...]
}
```

- `custom_version`: Created on first `/add-custom`
- Field is optional - missing if no custom repo configured

### Workflow

```
┌─────────────────────────────────────────────────────────┐
│  MAINTAINER: New skill / Update                         │
│  1. Add skill or update existing                        │
│  2. Bump VERSION (1 → 2)                                │
│  3. Update CHANGELOG.md                                 │
│  4. git push                                            │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  DEVELOPER: /claude-code-setup                          │
│  1. Checks ~/.claude/custom/VERSION vs installed.json   │
│  2. Shows: "Custom modules: v2 available (installed v1)"│
│  3. Option: "Upgrade custom" → git pull + install       │
└─────────────────────────────────────────────────────────┘
```

### Command Changes

**`/add-custom <url>`:**
1. Clone repo (as before)
2. NEW: Read VERSION from cloned repo
3. NEW: Write `custom_version` and `custom_url` to installed.json

**`/claude-code-setup`:**
1. Check base version (as before)
2. NEW: If `~/.claude/custom` exists:
   - Fetch remote: `git -C ~/.claude/custom fetch`
   - Compare local VERSION with remote VERSION
   - Show delta if available
3. NEW: Option "Upgrade custom" runs `/upgrade-custom`

**`/upgrade-custom`:**
1. `git pull` (as before)
2. NEW: Update `custom_version` in installed.json
3. NEW: Show new/changed modules

## Implementation

### Phase 1: Prepare custom repo
- [x] Create VERSION file (initial: 1)
- [x] Create CHANGELOG.md

### Phase 2: Extend /add-custom
- [x] After clone: Read VERSION
- [x] Write `custom_version` + `custom_url` to installed.json

### Phase 3: Extend /claude-code-setup
- [x] Detect custom repo
- [x] Fetch remote VERSION and compare
- [x] Add "Upgrade custom" option

### Phase 4: Extend /upgrade-custom
- [x] After pull: Read VERSION
- [x] Update `custom_version` in installed.json

## Alternatives Considered

| Alternative | Rejected because |
|-------------|------------------|
| No versioning | User doesn't learn about updates |
| Only CHANGELOG without VERSION | No automatic check possible |
| Git commit hash instead of VERSION | Less readable, harder to communicate |

## References

- [Record 002](002-custom-modules-directory.md) - Custom Modules Directory
- [Record 008](008-content-versioning.md) - Content Versioning (base)
- [Record 011](011-upgrade-command.md) - Upgrade Command

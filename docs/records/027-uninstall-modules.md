# Record 027: Uninstall/Remove Modules

## Status

Done

## Problem

Currently, modules (MCP servers, skills, plugins) can only be installed, not removed. Users who tried a module and no longer need it must manually:

1. Remove entries from `~/.claude.json` (MCP servers)
2. Delete directories from `~/.claude/skills/`
3. Uninstall plugins via `claude plugin remove`
4. Clean up `installed.json` manually

This is error-prone and contradicts the goal of a simple, guided installation.

## Proposed Solution

### 1. Extend install.sh

New flag `--remove`:

```bash
./install.sh --remove
```

Shows installed modules and allows selection for removal (toggle interface like installation).

### 2. Extend /claude-code-setup

The existing `/claude-code-setup` command already presents options interactively. Add "Remove modules" as a new option:

```
/claude-code-setup

What would you like to do?
1. Check for updates
2. Add modules
3. Remove modules    ← NEW
4. Show installed modules
```

No separate command needed - keeps UX consistent.

### 3. Technical Implementation

**For MCP Servers:**
- Remove entry from `~/.claude.json`
- If npx-based: No cleanup needed (npx caches itself)

**For Skills:**
- Delete directory from `~/.claude/skills/`
- Remove entry from `installed.json`

**For External Plugins:**
- Run `claude plugin remove <plugin-name>`
- Remove entry from `installed.json`

**For Custom Modules:**
- Remove from `~/.claude/custom/`
- Remove entry from `installed.json`

### 4. Safety

- Confirmation before deletion
- Show list of files/entries to be deleted
- `--yes` flag for non-interactive use (CI)

## Implementation Plan

1. [x] Create `lib/uninstall.sh` with core logic
2. [x] Add `--remove` flag to `install.sh`
3. [x] Toggle interface for module selection (like installation)
4. [x] Add "Remove modules" option to `/claude-code-setup` command
5. [x] Write tests (expect-based)
6. [x] Update documentation (website)

## Open Questions

- Should `--remove` show all module types at once or group by type?
- Should there be a `--remove-all` option for complete cleanup?

## References

- [Record 001: Modular Architecture](001-modular-architecture.md)
- [Record 026: External Plugins](026-external-plugins.md)

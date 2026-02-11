# Record 041: Custom Command Overrides, Extensions & Script Deployment

## Status

Implemented

---

## Problem

The `install.sh` supports custom **skills** and **MCP servers** from `~/.claude/custom/`, but does NOT support custom **commands** or **scripts**. This creates a gap in the custom modules system (Record 002):

1. **No command overrides**: Custom repos cannot replace base commands with custom versions. The installer copies commands ONLY from `commands/` — custom commands in `~/.claude/custom/commands/` are ignored.

2. **No command extensions**: A custom command that only adds a few steps on top of a base command would need to duplicate the entire base content. When the base command updates, the custom version becomes stale.

3. **No script deployment**: There is no mechanism to ship helper shell scripts that commands or skills reference. No `~/.claude/scripts/` directory concept exists.

**Real-world blocker:** A custom repo needs to override or extend base commands with additional logic and ship helper scripts. Without this, the "Override Principle" from Record 002 is only partially implemented.

## Options Considered

### Option A: Install-time merge

- Installer copies base commands to `~/.claude/commands/` (as today)
- If custom commands exist in `~/.claude/custom/commands/`, they overwrite base versions
- Custom commands can include a `{{base:command-name}}` marker — the installer replaces it with the base command content at copy time
- Result: one self-contained file per command, no extra reads at runtime

**Pros:**
- Claude reads one file per command (no extra file reads)
- No `_base/` directory needed
- Simple for Claude — just Markdown
- Conditional logic is just an instruction pattern within Extend (e.g., "if X, stop here; otherwise continue with base below")

**Cons:**
- Installer needs text substitution logic for `{{base:...}}` markers
- `--update` must re-merge custom+base (straightforward since base source is always available)

### Option B: Runtime reference (base in separate directory)

- Installer copies base commands to `~/.claude/commands/_base/`
- Custom commands reference base via: "Read and follow `~/.claude/commands/_base/catchup.md`"
- Claude reads two files at runtime when custom commands reference base

**Pros:**
- No install-time text processing
- Base always up to date in `_base/`

**Cons:**
- Claude must read two files (extra latency)
- `_base/` directory adds complexity
- Conditional routing requires Claude to decide whether to read a second file — adds cognitive load for no benefit since Extend covers conditional patterns

### Decision

**Option A (install-time merge)** because:
- One file per command = simpler for Claude, no extra reads
- Conditional logic doesn't need a separate mode — it's just an instruction pattern within Extend ("if condition, do X and stop; otherwise continue with base content below")
- The merge logic is simple: find `{{base:name}}`, replace with file content
- Aligns with the existing architecture: install-time produces static Markdown, nothing runs at runtime

## Solution

### Command Modes

Two modes, determined by whether the custom command contains a `{{base:...}}` marker:

| Mode | Detection | Behavior |
|------|-----------|----------|
| **Override** | No `{{base:...}}` marker | Custom replaces base entirely |
| **Extend** | Has `{{base:command-name}}` marker | Installer substitutes marker with base content |

### Extend Marker Syntax

```
{{base:catchup}}
```

- Format: `{{base:<command-name>}}` where command-name matches a file in `commands/` (without `.md`)
- Must be on its own line
- `command-name` must be alphanumeric + hyphens only (no `/`, `..`, or path separators — prevents path traversal)
- The installer replaces the entire line with the contents of the base command file
- If the referenced base command doesn't exist: replace marker with HTML comment `<!-- WARNING: base command 'name' not found -->` and print warning (avoids Claude interpreting raw marker as literal output)

### Extend Patterns

**Additive (prepend custom, then base):**
```markdown
# Custom Catchup

## Additional Steps
- Load team-specific skills
- Check internal tooling

---

{{base:catchup}}
```

**Conditional (custom gate, then base):**
```markdown
# Custom Catchup

## Step 0: Detect Project Type
Check if `settings.gradle` exists and contains "myframework":

### If detected:
- Read custom workflow skill
- Follow custom steps from that skill
- **Stop here** — do NOT continue with standard tasks below

### If NOT detected:
Continue with standard tasks below.

---

{{base:catchup}}
```

**Append (base first, then custom):**
```markdown
{{base:wrapup}}

---

## Additional Custom Steps
- Sync with internal dashboard
- Update team status
```

### Install Flow Changes

#### `do_install()` in `install.sh` (after base command copy, ~line 175)

```bash
# Override/extend with custom commands (if custom repo exists)
if [[ -d "$CUSTOM_DIR/commands" ]]; then
    local custom_commands=()
    for cmd in "$CUSTOM_DIR/commands/"*.md; do
        [[ -f "$cmd" ]] || continue
        filename=$(basename "$cmd")
        local base_name="${filename%.md}"

        if grep -q '{{base:' "$cmd"; then
            # Extend mode: merge base content into custom
            merge_command "$cmd" "$CLAUDE_DIR/commands/$filename"
            print_success "$filename (custom extend)"
        else
            # Override mode: replace entirely
            cp "$cmd" "$CLAUDE_DIR/commands/"
            print_success "$filename (custom override)"
        fi
        custom_commands+=("$filename")
    done

    # Track overrides in installed.json
    if [[ ${#custom_commands[@]} -gt 0 ]]; then
        set_installed_custom_commands "${custom_commands[@]}"
    fi
fi
```

#### `merge_command()` — new helper function

```bash
# Merge a custom command with base content
# Replaces {{base:name}} markers with base command file content
# Arguments: $1 = source custom file, $2 = target output file
merge_command() {
    local custom_file=$1
    local target_file=$2
    local tmp_file
    tmp_file=$(mktemp)

    cp "$custom_file" "$tmp_file"

    # Find and replace all {{base:name}} markers
    local marker base_name base_file
    while IFS= read -r marker; do
        # Extract command name from marker
        base_name=$(echo "$marker" | sed 's/.*{{base:\([^}]*\)}}.*/\1/')

        # Validate: alphanumeric + hyphens only (prevent path traversal)
        if [[ ! "$base_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            print_warning "Invalid base reference: $base_name (must be alphanumeric/hyphens)"
            continue
        fi

        base_file="$SCRIPT_DIR/commands/${base_name}.md"

        if [[ -f "$base_file" ]]; then
            # Replace marker line with base file content (awk handles multi-line safely)
            awk -v marker="$marker" -v file="$base_file" '
                $0 == marker { while ((getline line < file) > 0) print line; next }
                { print }
            ' "$tmp_file" > "${tmp_file}.new"
            mv "${tmp_file}.new" "$tmp_file"
        else
            # Replace marker with HTML comment (avoids Claude interpreting raw marker)
            sed "s|${marker}|<!-- WARNING: base command '${base_name}' not found -->|" \
                "$tmp_file" > "${tmp_file}.new"
            mv "${tmp_file}.new" "$tmp_file"
            print_warning "Base command not found: $base_name"
        fi
    done < <(grep '{{base:' "$tmp_file" || true)

    mv "$tmp_file" "$target_file"
}
```

#### `do_update()` in `lib/update.sh` (after base command update, ~line 78)

Same custom command override/extend logic as `do_install()`. After copying base commands, re-apply custom overrides and merges.

Additionally, **cleanup orphaned overrides**: compare `command_overrides` in `installed.json` against files currently in `$CUSTOM_DIR/commands/`. If a previously tracked override no longer exists in the custom repo, restore the base version:

```bash
# Cleanup: restore base for removed custom commands
local tracked_overrides
tracked_overrides=$(jq -r '.command_overrides[]?' "$INSTALLED_FILE" 2>/dev/null)
for override in $tracked_overrides; do
    if [[ ! -f "$CUSTOM_DIR/commands/$override" ]]; then
        # Custom command was removed — restore base
        if [[ -f "$SCRIPT_DIR/commands/$override" ]]; then
            cp "$SCRIPT_DIR/commands/$override" "$CLAUDE_DIR/commands/"
            print_info "$override restored to base (custom removed)"
        fi
    fi
done
```

### Script Deployment

#### Install flow (new section in `do_install()`, after commands)

```bash
# Install custom scripts (if custom repo has scripts)
if [[ -d "$CUSTOM_DIR/scripts" ]]; then
    local has_scripts=false
    for script in "$CUSTOM_DIR/scripts/"*; do
        [[ -f "$script" ]] || continue
        has_scripts=true
        break
    done

    if [[ "$has_scripts" = true ]]; then
        print_header "Installing Custom Scripts"
        mkdir -p "$CLAUDE_DIR/scripts"
        for script in "$CUSTOM_DIR/scripts/"*; do
            [[ -f "$script" ]] || continue
            filename=$(basename "$script")
            cp "$script" "$CLAUDE_DIR/scripts/"
            chmod +x "$CLAUDE_DIR/scripts/$filename"
            print_success "$filename"
        done
    fi
fi
```

Same logic in `do_update()`.

### Tracking in `installed.json`

Add two new fields:

```json
{
    "content_version": 54,
    "mcp": ["brave-search", "pdf-reader"],
    "skills": ["standards-shell", "custom:my-skill"],
    "external_plugins": ["code-review-ai"],
    "command_overrides": ["catchup.md", "wrapup.md"],
    "scripts": ["helper.sh"]
}
```

- `command_overrides`: Array of filenames that were overridden/extended by custom commands
- `scripts`: Array of installed script filenames

### `--list` Output Changes

Add to `list_modules()`:

```
Commands:
  catchup.md (custom override)
  wrapup.md (custom extend)
  design.md
  init-project.md

Custom Scripts:
  helper.sh
```

Commands with custom overrides/extends are marked. Base-only commands listed normally.

### `--remove` Support

Custom command overrides can be "removed" by restoring the base version:
- Remove from `command_overrides` tracking
- Re-copy base command to `~/.claude/commands/`

Scripts can be removed:
- Delete from `~/.claude/scripts/`
- Remove from `scripts` tracking

### Directory Structure

```
~/.claude/
├── commands/
│   ├── catchup.md          ← merged custom+base (extend)
│   ├── wrapup.md           ← custom only (override)
│   ├── design.md           ← base (no custom)
│   └── ...
├── scripts/                ← NEW (only when custom scripts exist)
│   └── helper.sh           ← from custom, chmod +x
└── custom/                 ← source repo
    ├── commands/
    │   ├── catchup.md      ← has {{base:catchup}}
    │   └── wrapup.md       ← no marker = override
    ├── scripts/
    │   └── helper.sh
    ├── mcp/
    └── skills/
```

### Custom Directory Setup

Update `do_install()` to also create `$CUSTOM_DIR/commands` and recognize it:

```bash
mkdir -p "$CUSTOM_DIR/commands"
mkdir -p "$CUSTOM_DIR/scripts"
```

Update `show_usage()` to document the new custom module types:

```
Custom Modules:
  Place custom modules in ~/.claude/custom/
  Structure: custom/{commands,scripts,mcp,skills}/
```

### `/claude-code-setup` Integration

The `/claude-code-setup` command (Phase 3) calls `./install.sh --update --yes`, which runs `do_update()`. Since custom command logic is added to `do_update()`, it works automatically via `/claude-code-setup`.

Additional changes needed:

#### `setup-status.sh` — report custom commands and scripts in JSON

Add to the JSON output:

```json
{
    "custom": {
        "configured": true,
        "commands": ["catchup.md", "wrapup.md"],
        "scripts": ["helper.sh"],
        ...
    }
}
```

Discovery logic (after existing custom skills/MCP discovery):

```bash
# Discover custom commands
custom_commands=()
if [[ -d "$CUSTOM_DIR/commands" ]]; then
    for f in "$CUSTOM_DIR/commands/"*.md; do
        [[ -f "$f" ]] || continue
        custom_commands+=("$(basename "$f")")
    done
fi

# Discover custom scripts
custom_scripts=()
if [[ -d "$CUSTOM_DIR/scripts" ]]; then
    for f in "$CUSTOM_DIR/scripts/"*; do
        [[ -f "$f" ]] || continue
        custom_scripts+=("$(basename "$f")")
    done
fi
```

#### `claude-code-setup.md` — show custom commands/scripts in status

Add to Phase 2 status display:

```
Custom commands: catchup.md (extend), wrapup.md (override)
Custom scripts: helper.sh
```

Only shown when `custom.commands` or `custom.scripts` arrays are non-empty.

### Edge Cases

1. **Custom command references non-existent base**: Marker replaced with `<!-- WARNING: base command 'name' not found -->`, warning printed. Avoids Claude interpreting raw `{{base:...}}` as literal output.
2. **Path traversal attempt** (`{{base:../../etc/passwd}}`): Rejected by validation — `base_name` must match `^[a-zA-Z0-9_-]+$`. Warning printed, marker skipped.
3. **Multiple `{{base:...}}` markers in one file**: All are resolved sequentially (unusual but supported).
4. **Cross-reference** (`{{base:other-command}}`): Supported — a custom catchup could include base wrapup content (unusual but no reason to block it).
5. **No custom repo**: Zero behavior change, fully backward compatible.
6. **`--update` with custom commands**: Base commands updated first, then custom overrides/merges re-applied from `$CUSTOM_DIR/commands/`.
7. **`/claude-code-setup` update**: Works automatically via `do_update()` — no special handling needed.
8. **Custom command removed from custom repo**: During `--update`, cleanup previously overridden commands that no longer exist in `$CUSTOM_DIR/commands/` — restore the base version and remove from `command_overrides` tracking.
9. **Base command renamed/removed**: Custom extend references a base that no longer exists. Warning is printed and marker replaced with HTML comment. Custom repo maintainer must update their command.

## User Stories

### Story 1: Custom Script Deployment
**As a** custom repo maintainer,
**I want** scripts from `~/.claude/custom/scripts/` to be installed to `~/.claude/scripts/` with executable permissions,
**So that** my commands and skills can reference helper scripts.

**Acceptance Criteria:**

- Given a custom repo with `scripts/helper.sh`,
  When `install.sh` runs,
  Then `~/.claude/scripts/helper.sh` exists and is executable (`chmod +x`).

- Given no custom scripts exist,
  When `install.sh` runs,
  Then no `scripts/` directory is created.

- Given `--update` runs with custom scripts,
  When scripts exist in `~/.claude/custom/scripts/`,
  Then scripts are re-copied to `~/.claude/scripts/`.

**Priority:** High
**Status:** Pending

**Note:** Implemented first because custom commands may reference scripts.

### Story 2: Custom Command Override & Extend
**As a** custom repo maintainer,
**I want** my custom commands to override or extend base commands during installation,
**So that** my custom workflows are deployed without duplicating base command content.

**Acceptance Criteria:**

- Given a custom repo with `commands/wrapup.md` (no `{{base:...}}`),
  When `install.sh` runs,
  Then `~/.claude/commands/wrapup.md` contains the custom version (override).

- Given a custom command with `{{base:catchup}}` marker,
  When `install.sh` runs,
  Then the marker is replaced with base catchup content (extend).

- Given no custom repo exists,
  When `install.sh` runs,
  Then behavior is identical to today (backward compatible).

- Given a `{{base:nonexistent}}` marker references a missing base command,
  When `install.sh` runs,
  Then the marker is replaced with `<!-- WARNING: ... -->` and a warning is printed.

- Given a `{{base:../../etc/passwd}}` marker (path traversal attempt),
  When `install.sh` runs,
  Then validation rejects it (alphanumeric + hyphens only) and a warning is printed.

- Given custom commands exist and `--update` runs,
  When base commands are updated first,
  Then custom overrides/merges are re-applied on top of new base content.

- Given a previously overridden command is removed from `$CUSTOM_DIR/commands/`,
  When `--update` runs,
  Then the base version is restored and tracking is updated (cleanup).

**Priority:** High
**Status:** Pending

### Story 3: Tracking, `--list` & `/claude-code-setup` Status
**As a** user,
**I want** to see which commands are overridden/extended and which scripts are installed,
**So that** I can understand what's customized in my installation.

**Acceptance Criteria:**

- Given commands were overridden/extended,
  When `--list` runs,
  Then overridden commands show "(custom override)" or "(custom extend)".

- Given scripts are installed,
  When `--list` runs,
  Then a "Custom Scripts" section lists them.

- Given `installed.json`,
  Then it contains `command_overrides` and `scripts` arrays tracking custom modules.

- Given `setup-status.sh` runs with a custom repo that has commands/scripts,
  When the JSON is output,
  Then `custom.commands` and `custom.scripts` arrays are populated.

- Given `/claude-code-setup` runs (Phase 2),
  When custom commands/scripts exist,
  Then the status display shows "Custom commands: ..." and "Custom scripts: ...".

**Priority:** Medium
**Status:** Pending

### Story 4: Tests
**As a** developer,
**I want** test scenarios covering custom command overrides, extends, and scripts,
**So that** regressions are caught automatically.

**Acceptance Criteria:**

- Given a test with custom override command (no marker),
  When install runs,
  Then `~/.claude/commands/` contains the custom version.

- Given a test with extend marker (`{{base:catchup}}`),
  When install runs,
  Then the merged content contains both custom and base text.

- Given a test with custom script,
  When install runs,
  Then the script exists at `~/.claude/scripts/` and is executable.

- Given a test with `--update` and custom commands,
  When update runs,
  Then custom overrides are re-applied after base update.

- Given a test with `{{base:../../etc/passwd}}` (path traversal),
  When install runs,
  Then the marker is rejected with a warning.

- Given a test with `{{base:nonexistent}}` (missing base),
  When install runs,
  Then the marker is replaced with an HTML comment warning.

- Given a test where a custom command was removed between updates,
  When `--update` runs,
  Then the base version is restored.

- Given no custom repo,
  When existing tests run,
  Then all pass unchanged.

**Priority:** Medium
**Status:** Pending

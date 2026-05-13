#!/bin/bash

# Module uninstallation logic
# Note: SELECTED_REMOVE array is declared in lib/modules.sh

# ============================================
# UNINSTALL FUNCTIONS
# ============================================

# Remove MCP server from ~/.claude.json
uninstall_mcp() {
    local name=$1
    local display_name="${name#custom:}"

    if [[ ! -f "$MCP_CONFIG_FILE" ]]; then
        print_warning "No MCP config file found"
        return 1
    fi

    # Check if MCP server exists in config
    if ! jq -e ".mcpServers[\"$display_name\"]" "$MCP_CONFIG_FILE" > /dev/null 2>&1; then
        print_warning "$display_name not found in MCP config"
        return 1
    fi

    # Remove from ~/.claude.json
    if jq "del(.mcpServers[\"$display_name\"])" "$MCP_CONFIG_FILE" > "$MCP_CONFIG_FILE.tmp"; then
        mv "$MCP_CONFIG_FILE.tmp" "$MCP_CONFIG_FILE"
    else
        rm -f "$MCP_CONFIG_FILE.tmp"
        print_warning "Failed to update MCP config"
        return 1
    fi

    # Remove from installed.json
    remove_from_installed "mcp" "$name"

    return 0
}

# Remove skill from ~/.claude/skills/
uninstall_skill() {
    local name=$1
    local skill_name="${name#custom:}"
    local skill_dir="$CLAUDE_DIR/skills/$skill_name"

    if [[ ! -d "$skill_dir" ]]; then
        print_warning "Skill directory not found: $skill_dir"
        return 1
    fi

    # Remove skill directory
    rm -rf "$skill_dir"

    # Remove from installed.json
    remove_from_installed "skills" "$name"

    return 0
}

# Remove a custom command override; restore base version if it exists.
# Usage: uninstall_custom_command <filename>   # e.g. "catchup.md"
# Returns: 0 on success (file removed or base restored). Non-zero if the
# base copy fails — tracking is left intact in that case so the user can
# retry without losing the override entry.
uninstall_custom_command() {
    local filename=$1
    local target="$CLAUDE_DIR/commands/$filename"
    local base="$SCRIPT_DIR/commands/$filename"

    if [[ -f "$base" ]]; then
        if ! cp "$base" "$target"; then
            print_warning "Failed to restore base command: $filename"
            return 1
        fi
    else
        rm -f "$target"
    fi

    remove_from_installed "command_overrides" "$filename"
    return 0
}

# Remove a custom script that was installed from ~/.claude/custom/scripts/.
# Usage: uninstall_custom_script <filename>
uninstall_custom_script() {
    local filename=$1
    local target="$CLAUDE_DIR/scripts/$filename"

    rm -f "$target"
    remove_from_installed "scripts" "$filename"
    return 0
}

# Remove external plugin via claude CLI
uninstall_external_plugin() {
    local name=$1

    # Check if claude CLI is available
    if ! command -v claude &>/dev/null; then
        print_warning "claude CLI not found, cannot remove plugin"
        return 1
    fi

    # Remove plugin
    if claude plugin remove "$name" 2>/dev/null; then
        # Remove from installed.json
        remove_from_installed "external_plugins" "$name"
        return 0
    else
        print_warning "Failed to remove plugin: $name"
        return 1
    fi
}

# Remove module from installed.json
remove_from_installed() {
    local category=$1
    local module=$2

    if [[ ! -f "$INSTALLED_FILE" ]]; then
        return 0
    fi

    # Remove from array in installed.json
    if jq ".${category} = (.${category} // [] | map(select(. != \"${module}\")))" \
        "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp"; then
        mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"
    else
        rm -f "$INSTALLED_FILE.tmp"
        print_warning "Failed to update installed.json"
        return 1
    fi
}

# Interactive selection for modules to remove
select_modules_to_remove() {
    SELECTED_REMOVE=()

    # Skip in non-interactive mode
    if [[ "$YES_MODE" = "true" ]]; then
        print_warning "Remove requires interactive mode. Cannot use --yes."
        return 1
    fi

    # Get all installed modules (using xargs for whitespace trimming)
    local mcp_list skills_list plugins_list
    mcp_list=$(jq -r '.mcp[]? // empty' "$INSTALLED_FILE" 2>/dev/null | tr '\n' ' ' | xargs)
    skills_list=$(jq -r '.skills[]? // empty' "$INSTALLED_FILE" 2>/dev/null | tr '\n' ' ' | xargs)
    plugins_list=$(jq -r '.external_plugins[]? // empty' "$INSTALLED_FILE" 2>/dev/null | tr '\n' ' ' | xargs)

    # Check if anything is installed
    if [[ -z "$mcp_list" ]] && [[ -z "$skills_list" ]] && [[ -z "$plugins_list" ]]; then
        echo ""
        echo "No modules installed to remove."
        return 1
    fi

    # Build combined list with prefixes for identification
    local all_modules=""
    local all_descs=""
    local module

    # Add MCP servers
    for module in $mcp_list; do
        all_modules="$all_modules mcp:$module"
        if [[ -n "$all_descs" ]]; then
            all_descs="$all_descs|MCP Server"
        else
            all_descs="MCP Server"
        fi
    done

    # Add skills
    for module in $skills_list; do
        all_modules="$all_modules skill:$module"
        if [[ -n "$all_descs" ]]; then
            all_descs="$all_descs|Skill"
        else
            all_descs="Skill"
        fi
    done

    # Add plugins
    for module in $plugins_list; do
        all_modules="$all_modules plugin:$module"
        if [[ -n "$all_descs" ]]; then
            all_descs="$all_descs|External Plugin"
        else
            all_descs="External Plugin"
        fi
    done

    # Trim leading space
    all_modules="${all_modules# }"

    if [[ -z "$all_modules" ]]; then
        echo ""
        echo "No modules installed to remove."
        return 1
    fi

    echo ""
    echo "Select modules to remove (toggle with number/space, Enter to confirm):"
    echo ""

    # Use existing interactive_select with empty defaults (nothing pre-selected)
    interactive_select "$all_modules" "$all_descs" "" "" "false" "SELECTED_REMOVE"
}

# Execute removal of selected modules
do_remove() {
    echo ""
    echo "Claude Code Setup - Remove Modules"
    echo "==================================="

    # Ensure jq is available
    if ! command -v jq &>/dev/null; then
        print_error "jq is required but not installed"
        return 1
    fi

    # Check for installed.json
    if [[ ! -f "$INSTALLED_FILE" ]]; then
        echo ""
        echo "No installation found. Nothing to remove."
        return 0
    fi

    # Select modules to remove
    if ! select_modules_to_remove; then
        return 0
    fi

    # Check if anything was selected
    if [[ ${#SELECTED_REMOVE[@]} -eq 0 ]]; then
        echo ""
        echo "No modules selected for removal."
        return 0
    fi

    # Show what will be removed
    print_header "Modules to Remove"
    local item
    for item in "${SELECTED_REMOVE[@]}"; do
        echo "  - $item"
    done

    # Confirm removal
    echo ""
    local confirm
    if confirm=$(read_input "Remove these modules? (y/N): "); then
        if [[ "$confirm" != "y" ]] && [[ "$confirm" != "Y" ]]; then
            echo "Cancelled."
            return 0
        fi
    else
        echo "Non-interactive environment. Cancelled."
        return 1
    fi

    # Execute removal
    print_header "Removing Modules"

    local type name display_name
    for item in "${SELECTED_REMOVE[@]}"; do
        type="${item%%:*}"
        name="${item#*:}"
        display_name="${name#custom:}"

        case "$type" in
            mcp)
                if uninstall_mcp "$name"; then
                    print_success "Removed MCP server: $display_name"
                fi
                ;;
            skill)
                if uninstall_skill "$name"; then
                    print_success "Removed skill: $display_name"
                fi
                ;;
            plugin)
                if uninstall_external_plugin "$name"; then
                    print_success "Removed plugin: $name"
                fi
                ;;
        esac
    done

    # Rebuild CLAUDE.md so removed modules disappear from tables
    build_claude_md

    print_header "Removal Complete"
    echo ""
    echo "Removed ${#SELECTED_REMOVE[@]} module(s)."
    echo ""
    echo "⚠️  IMPORTANT: Restart Claude Code now."
    echo "   Tools (Read, Bash, etc.) may not work until restart."
    echo ""
}

# Remove the entire custom modules repo and ALL its installed artifacts.
# Usage: do_remove_custom
# No arguments — only one custom repo can be active at a time (CUSTOM_DIR is a
# single hardcoded path), so there's nothing to disambiguate.
#
# Removes:
#   - all custom skills (skills[] entries with custom: prefix)
#   - all custom MCPs (mcp[] entries with custom: prefix)
#   - all custom command overrides (restores base versions if available)
#   - all custom scripts
#   - $CUSTOM_DIR (the git clone)
#   - custom_url and custom_version fields from installed.json
# Rebuilds CLAUDE.md at the end.
do_remove_custom() {
    echo ""
    echo "Claude Code Setup - Remove Custom Repo"
    echo "======================================="

    install_jq

    if [[ ! -f "$INSTALLED_FILE" ]]; then
        echo ""
        echo "No installation found. Nothing to remove."
        return 0
    fi

    local custom_url
    custom_url=$(jq -r '.custom_url // empty' "$INSTALLED_FILE" 2>/dev/null || echo "")

    if [[ -z "$custom_url" ]] && [[ ! -d "$CUSTOM_DIR" ]]; then
        echo ""
        echo "No custom repo registered (installed.json has no custom_url, and"
        echo "$CUSTOM_DIR does not exist). Nothing to remove."
        return 0
    fi

    if [[ -n "$custom_url" ]]; then
        print_header "Removing Custom Repo: $custom_url"
    else
        print_header "Removing Custom Repo"
    fi

    # Build inventory from installed.json (snapshot before mutation).
    # Skills and MCPs carry a "custom:" prefix because they share a tracking
    # array with base modules. command_overrides[] and scripts[] do NOT — by
    # design they belong solely to the custom repo (base commands aren't
    # tracked there, base ships no scripts), so we take the arrays as-is.
    local custom_skills custom_mcps custom_cmds custom_scripts
    custom_skills=$(jq -r '.skills[]? | select(startswith("custom:"))' "$INSTALLED_FILE" 2>/dev/null || true)
    custom_mcps=$(jq -r '.mcp[]? | select(startswith("custom:"))' "$INSTALLED_FILE" 2>/dev/null || true)
    custom_cmds=$(jq -r '.command_overrides[]? // empty' "$INSTALLED_FILE" 2>/dev/null || true)
    custom_scripts=$(jq -r '.scripts[]? // empty' "$INSTALLED_FILE" 2>/dev/null || true)

    # Tracking can lie — skills may exist on disk (or in ~/.claude.json) that
    # the custom repo provided but that never made it into installed.json (or
    # were dropped by a partial install/update). Snapshot the SOURCE listings
    # before deleting CUSTOM_DIR; we do a second pass below that catches
    # untracked artifacts using these as ground truth.
    local source_skills="" source_mcps="" source_cmds="" source_scripts=""
    if [[ -d "$CUSTOM_DIR/skills" ]]; then
        for d in "$CUSTOM_DIR/skills/"*/; do
            [[ -d "$d" ]] || continue
            source_skills+="$(basename "$d")"$'\n'
        done
    fi
    if [[ -d "$CUSTOM_DIR/mcp" ]]; then
        for f in "$CUSTOM_DIR/mcp/"*.json; do
            [[ -f "$f" ]] || continue
            source_mcps+="$(basename "$f" .json)"$'\n'
        done
    fi
    if [[ -d "$CUSTOM_DIR/commands" ]]; then
        for f in "$CUSTOM_DIR/commands/"*.md; do
            [[ -f "$f" ]] || continue
            source_cmds+="$(basename "$f")"$'\n'
        done
    fi
    if [[ -d "$CUSTOM_DIR/scripts" ]]; then
        for f in "$CUSTOM_DIR/scripts/"*; do
            [[ -f "$f" ]] || continue
            source_scripts+="$(basename "$f")"$'\n'
        done
    fi

    # External plugins are installed via claude-CLI from a marketplace; the
    # custom repo can REGISTER additional marketplaces/plugins via
    # external-plugins.json, but installed.json doesn't track which plugins
    # originated from the custom source vs. base. We cannot safely remove
    # them automatically, so we surface a notice if any are installed.
    local external_count
    external_count=$(jq -r '.external_plugins // [] | length' "$INSTALLED_FILE" 2>/dev/null || echo 0)

    local skills_removed=0
    local mcps_removed=0
    local cmds_removed=0
    local scripts_removed=0
    local item name

    # Counters tally SUCCESSFUL removals only. When uninstall_skill/uninstall_mcp
    # fail because the artifact is already gone, we still clean up the tracking
    # entry via remove_from_installed, but don't count it toward the totals.
    #
    # Note: `: $((var++))` (not `((var++))`) avoids `set -e` exiting when the
    # pre-increment expression returns 0. The `:` no-op consumes the value.

    # === Pass 1: Tracked artifacts (installed.json is the source of truth) ===

    # 1. Skills
    while IFS= read -r item; do
        [[ -z "$item" ]] && continue
        if uninstall_skill "$item"; then
            print_success "Removed skill: ${item#custom:}"
            : $((skills_removed++))
        else
            remove_from_installed "skills" "$item"
        fi
    done <<< "$custom_skills"

    # 2. MCPs
    while IFS= read -r item; do
        [[ -z "$item" ]] && continue
        if uninstall_mcp "$item"; then
            print_success "Removed MCP server: ${item#custom:}"
            : $((mcps_removed++))
        else
            remove_from_installed "mcp" "$item"
        fi
    done <<< "$custom_mcps"

    # 3. Commands (restore base where available)
    while IFS= read -r item; do
        [[ -z "$item" ]] && continue
        if uninstall_custom_command "$item"; then
            if [[ -f "$SCRIPT_DIR/commands/$item" ]]; then
                print_success "Restored base command: $item"
            else
                print_success "Removed custom command: $item"
            fi
            : $((cmds_removed++))
        fi
    done <<< "$custom_cmds"

    # 4. Scripts
    while IFS= read -r item; do
        [[ -z "$item" ]] && continue
        if uninstall_custom_script "$item"; then
            print_success "Removed script: $item"
            : $((scripts_removed++))
        fi
    done <<< "$custom_scripts"

    # === Pass 2: Untracked artifacts (source snapshot is the source of truth) ===
    # Anything the custom repo shipped that's still on disk gets removed, even
    # if tracking missed it. Guard against name collisions with base artifacts
    # ($SCRIPT_DIR/...) so we never wipe a shipped module by accident.

    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        [[ -d "$CLAUDE_DIR/skills/$name" ]] || continue
        if [[ -d "$SCRIPT_DIR/skills/$name" ]]; then
            print_warning "Skipped untracked skill $name (also a base skill)"
            continue
        fi
        rm -rf "$CLAUDE_DIR/skills/$name"
        remove_from_installed "skills" "$name"
        remove_from_installed "skills" "custom:$name"
        print_success "Removed untracked skill: $name"
        : $((skills_removed++))
    done <<< "$source_skills"

    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        jq -e ".mcpServers[\"$name\"]" "$MCP_CONFIG_FILE" > /dev/null 2>&1 || continue
        if [[ -f "$SCRIPT_DIR/mcp/$name.json" ]]; then
            print_warning "Skipped untracked MCP $name (also a base MCP)"
            continue
        fi
        if jq "del(.mcpServers[\"$name\"])" "$MCP_CONFIG_FILE" > "$MCP_CONFIG_FILE.tmp"; then
            mv "$MCP_CONFIG_FILE.tmp" "$MCP_CONFIG_FILE"
            remove_from_installed "mcp" "$name"
            remove_from_installed "mcp" "custom:$name"
            print_success "Removed untracked MCP server: $name"
            : $((mcps_removed++))
        else
            rm -f "$MCP_CONFIG_FILE.tmp"
            print_warning "Failed to remove untracked MCP $name from $MCP_CONFIG_FILE"
        fi
    done <<< "$source_mcps"

    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        [[ -f "$CLAUDE_DIR/commands/$name" ]] || continue
        # If a base version exists, the file is already in its base state (or
        # will be restored). If not, the override file is untracked custom
        # content — but we mustn't blindly delete it; the file might have been
        # locally modified by the user. Only act if file content matches the
        # source we just deleted — too late, source is gone. Fall back to
        # restoring base if available, else leave the file in place with a
        # warning.
        if [[ -f "$SCRIPT_DIR/commands/$name" ]]; then
            cp "$SCRIPT_DIR/commands/$name" "$CLAUDE_DIR/commands/$name"
            remove_from_installed "command_overrides" "$name"
            print_success "Restored base command: $name (was untracked)"
            : $((cmds_removed++))
        else
            print_warning "Kept $CLAUDE_DIR/commands/$name (no base to restore, untracked)"
        fi
    done <<< "$source_cmds"

    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        [[ -f "$CLAUDE_DIR/scripts/$name" ]] || continue
        rm -f "$CLAUDE_DIR/scripts/$name"
        remove_from_installed "scripts" "$name"
        print_success "Removed untracked script: $name"
        : $((scripts_removed++))
    done <<< "$source_scripts"

    # 5. Delete the git clone
    if [[ -d "$CUSTOM_DIR" ]]; then
        rm -rf "$CUSTOM_DIR"
        print_success "Removed $CUSTOM_DIR"
    fi

    # 6. Clear custom_url and custom_version from installed.json
    if jq 'del(.custom_url) | del(.custom_version)' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp"; then
        mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"
        print_success "Cleared custom_url and custom_version from installed.json"
    else
        rm -f "$INSTALLED_FILE.tmp"
        print_warning "Failed to update installed.json"
    fi

    # 7. Rebuild CLAUDE.md
    print_header "Rebuilding CLAUDE.md"
    build_claude_md
    print_success "CLAUDE.md updated"

    print_header "Removal Complete"
    echo ""
    echo "Removed:"
    echo "  - $skills_removed skill(s)"
    echo "  - $mcps_removed MCP server(s)"
    echo "  - $cmds_removed command(s)"
    echo "  - $scripts_removed script(s)"
    echo ""
    if (( external_count > 0 )); then
        print_warning "$external_count external plugin(s) remain installed."
        echo "    External plugins are managed via the claude CLI and may have been"
        echo "    registered by the custom repo. Review with:"
        echo "      jq '.external_plugins' \"$INSTALLED_FILE\""
        echo "    Remove with:"
        echo "      claude plugin remove <id>"
        echo ""
    fi
    if (( mcps_removed > 0 )); then
        echo "IMPORTANT: Restart Claude Code to deactivate removed MCP servers."
        echo ""
    fi
}

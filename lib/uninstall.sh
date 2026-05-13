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
uninstall_custom_command() {
    local filename=$1
    local target="$CLAUDE_DIR/commands/$filename"
    local base="$SCRIPT_DIR/commands/$filename"

    if [[ -f "$base" ]]; then
        cp "$base" "$target"
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

    # Build inventory from installed.json (snapshot before mutation)
    local custom_skills custom_mcps custom_cmds custom_scripts
    custom_skills=$(jq -r '.skills[]? | select(startswith("custom:"))' "$INSTALLED_FILE" 2>/dev/null || true)
    custom_mcps=$(jq -r '.mcp[]? | select(startswith("custom:"))' "$INSTALLED_FILE" 2>/dev/null || true)
    custom_cmds=$(jq -r '.command_overrides[]? // empty' "$INSTALLED_FILE" 2>/dev/null || true)
    custom_scripts=$(jq -r '.scripts[]? // empty' "$INSTALLED_FILE" 2>/dev/null || true)

    local skills_removed=0
    local mcps_removed=0
    local cmds_removed=0
    local scripts_removed=0
    local item

    # 1. Skills
    # uninstall_skill / uninstall_mcp fail when the artifact is already gone,
    # leaving the tracking entry behind. For a full custom-repo removal we
    # also want stale tracking entries cleaned up, so fall back to
    # remove_from_installed if the artifact-level uninstall returns non-zero.
    if [[ -n "$custom_skills" ]]; then
        while IFS= read -r item; do
            [[ -z "$item" ]] && continue
            if uninstall_skill "$item"; then
                print_success "Removed skill: ${item#custom:}"
            else
                remove_from_installed "skills" "$item"
            fi
            ((skills_removed++)) || true
        done <<< "$custom_skills"
    fi

    # 2. MCPs
    if [[ -n "$custom_mcps" ]]; then
        while IFS= read -r item; do
            [[ -z "$item" ]] && continue
            if uninstall_mcp "$item"; then
                print_success "Removed MCP server: ${item#custom:}"
            else
                remove_from_installed "mcp" "$item"
            fi
            ((mcps_removed++)) || true
        done <<< "$custom_mcps"
    fi

    # 3. Commands (restore base where available)
    if [[ -n "$custom_cmds" ]]; then
        while IFS= read -r item; do
            [[ -z "$item" ]] && continue
            if uninstall_custom_command "$item"; then
                if [[ -f "$SCRIPT_DIR/commands/$item" ]]; then
                    print_success "Restored base command: $item"
                else
                    print_success "Removed custom command: $item"
                fi
                ((cmds_removed++)) || true
            fi
        done <<< "$custom_cmds"
    fi

    # 4. Scripts
    if [[ -n "$custom_scripts" ]]; then
        while IFS= read -r item; do
            [[ -z "$item" ]] && continue
            if uninstall_custom_script "$item"; then
                print_success "Removed script: $item"
                ((scripts_removed++)) || true
            fi
        done <<< "$custom_scripts"
    fi

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
    if (( mcps_removed > 0 )); then
        echo "⚠️  IMPORTANT: Restart Claude Code to deactivate removed MCP servers."
        echo ""
    fi
}

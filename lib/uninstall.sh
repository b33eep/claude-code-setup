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

    print_header "Removal Complete"
    echo ""
    echo "Removed ${#SELECTED_REMOVE[@]} module(s)."
    echo ""
    echo "⚠️  IMPORTANT: Restart Claude Code now."
    echo "   Tools (Read, Bash, etc.) may not work until restart."
    echo ""
}

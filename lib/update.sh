#!/bin/bash

# Update installation logic

# Run version migrations
# $1: from_version, $2: to_version
run_migrations() {
    local from_v=$1
    local to_v=$2

    # v20: Remove /upgrade-custom (replaced by /claude-code-setup)
    if [[ "$from_v" -lt 20 ]] && [[ "$to_v" -ge 20 ]]; then
        if [[ -f "$CLAUDE_DIR/commands/upgrade-custom.md" ]]; then
            rm -f "$CLAUDE_DIR/commands/upgrade-custom.md"
            print_info "Removed obsolete upgrade-custom.md (use /claude-code-setup instead)"
        fi
    fi

    # v16: Rename /clear-session to /wrapup
    if [[ "$from_v" -lt 16 ]] && [[ "$to_v" -ge 16 ]]; then
        if [[ -f "$CLAUDE_DIR/commands/clear-session.md" ]]; then
            rm -f "$CLAUDE_DIR/commands/clear-session.md"
            print_info "Removed obsolete clear-session.md (renamed to wrapup.md)"
        fi
    fi
}

# Update all installed modules
do_update() {
    echo ""
    echo "Claude Code Setup - Update"
    echo "=========================="

    init_installed_json

    # Check content version
    local installed_v
    local available_v
    installed_v=$(get_installed_content_version)
    available_v=$(get_content_version)

    if [[ "$installed_v" -eq "$available_v" ]]; then
        echo ""
        echo "Content version: v$available_v (up to date)"
        echo "Nothing to update."
        echo ""
        exit 0
    fi

    echo ""
    echo "Content version: v$installed_v → v$available_v"
    echo "See CHANGELOG.md for details."
    echo ""

    if [[ "$YES_MODE" = "false" ]]; then
        read -rp "Proceed? (y/N): " confirm
        if [[ "$confirm" != "y" ]] && [[ "$confirm" != "Y" ]]; then
            echo "Cancelled."
            exit 0
        fi
    fi

    # Run migrations
    run_migrations "$installed_v" "$available_v"

    # Update commands
    print_header "Updating Commands"

    local filename
    for cmd in "$SCRIPT_DIR/commands/"*.md; do
        [[ -f "$cmd" ]] || continue
        filename=$(basename "$cmd")
        cp "$cmd" "$CLAUDE_DIR/commands/"
        print_success "$filename"
    done

    # Update project template
    mkdir -p "$CLAUDE_DIR/templates"
    cp "$SCRIPT_DIR/templates/project-CLAUDE.md" "$CLAUDE_DIR/templates/CLAUDE.template.md"
    print_success "Project template updated"

    # Update skills
    print_header "Updating Skills"

    local source_dir
    local display_name
    local name
    local target_dir
    local skill

    while IFS= read -r skill; do
        [[ -n "$skill" ]] || continue
        source_dir=""
        display_name=""

        if [[ "$skill" == custom:* ]]; then
            name="${skill#custom:}"
            source_dir="$CUSTOM_DIR/skills/$name"
            display_name="$name (custom)"
        else
            source_dir="$SCRIPT_DIR/skills/$skill"
            display_name="$skill"
        fi

        if [[ -d "$source_dir" ]]; then
            target_dir="$CLAUDE_DIR/skills/$(basename "$source_dir")"
            rm -rf "$target_dir"
            cp -r "$source_dir" "$target_dir"
            print_success "$display_name"
        else
            print_warning "$display_name (source not found, skipped)"
        fi
    done < <(get_installed "skills")

    # Rebuild CLAUDE.md with dynamic tables (after skills are updated)
    print_header "Rebuilding CLAUDE.md"
    build_claude_md
    print_success "CLAUDE.md rebuilt"

    # Configure hooks (for users updating from pre-v33)
    print_header "Hooks"
    configure_hooks

    # Configure Agent Teams (for users updating from pre-Agent-Teams)
    print_header "Agent Teams"
    configure_agent_teams

    # Update content version
    set_installed_content_version "$available_v"

    echo ""
    print_success "Update complete! (v$available_v)"
    echo ""
    echo "⚠️  IMPORTANT: Restart Claude Code now."
    echo "   Tools (Read, Bash, etc.) may not work until restart."

    # Check for new modules (skip in non-interactive mode)
    if [[ "$YES_MODE" = "false" ]]; then
        local new_mcp new_skills
        new_mcp=$(get_new_mcp)
        new_skills=$(get_new_skills)

        if [[ -n "$new_mcp" ]] || [[ -n "$new_skills" ]]; then
            echo ""
            print_header "New Modules Available"

            if [[ -n "$new_mcp" ]]; then
                echo "  MCP: $new_mcp"
            fi
            if [[ -n "$new_skills" ]]; then
                echo "  Skills: $new_skills"
            fi

            echo ""
            read -rp "Install new modules? (y/N): " install_new
            if [[ "$install_new" = "y" ]] || [[ "$install_new" = "Y" ]]; then
                echo ""
                select_mcp "add"
                select_skills "add"

                # Install selected MCP servers
                if [[ ${#SELECTED_MCP[@]} -gt 0 ]]; then
                    for mcp in "${SELECTED_MCP[@]}"; do
                        print_header "Installing MCP: $mcp"
                        if install_mcp "$mcp"; then
                            add_to_installed "mcp" "$mcp"
                            print_success "Installed $mcp"
                        fi
                    done
                fi

                # Install selected skills
                if [[ ${#SELECTED_SKILLS[@]} -gt 0 ]]; then
                    for skill in "${SELECTED_SKILLS[@]}"; do
                        print_header "Installing Skill: $skill"
                        if install_skill "$skill"; then
                            add_to_installed "skills" "$skill"
                            print_success "Installed $skill"
                        fi
                    done
                fi

                # Rebuild CLAUDE.md with new modules
                if [[ ${#SELECTED_MCP[@]} -gt 0 ]] || [[ ${#SELECTED_SKILLS[@]} -gt 0 ]]; then
                    build_claude_md
                fi
            fi
        fi
    fi

    echo ""
}

#!/bin/bash

# Module discovery, listing, and selection

# Global arrays for module selection (used across functions)
SELECTED_MCP=()
SELECTED_SKILLS=()

# Get new (not installed) modules
# Returns space-separated list of module names
get_new_mcp() {
    local new_mcp=""
    local name

    for f in "$SCRIPT_DIR/mcp/"*.json; do
        [[ -f "$f" ]] || continue
        name=$(basename "$f" .json)
        if ! is_installed "mcp" "$name"; then
            new_mcp="$new_mcp $name"
        fi
    done

    if [[ -d "$CUSTOM_DIR/mcp" ]]; then
        for f in "$CUSTOM_DIR/mcp/"*.json; do
            [[ -f "$f" ]] || continue
            name=$(basename "$f" .json)
            if ! is_installed "mcp" "custom:$name"; then
                new_mcp="$new_mcp custom:$name"
            fi
        done
    fi

    echo "$new_mcp" | xargs
}

get_new_skills() {
    local new_skills=""
    local name

    for d in "$SCRIPT_DIR/skills/"*/; do
        [[ -d "$d" ]] || continue
        name=$(basename "$d")
        if ! is_installed "skills" "$name"; then
            new_skills="$new_skills $name"
        fi
    done

    if [[ -d "$CUSTOM_DIR/skills" ]]; then
        for d in "$CUSTOM_DIR/skills/"*/; do
            [[ -d "$d" ]] || continue
            name=$(basename "$d")
            if ! is_installed "skills" "custom:$name"; then
                new_skills="$new_skills custom:$name"
            fi
        done
    fi

    echo "$new_skills" | xargs
}

# List all modules (installed and available)
list_modules() {
    print_header "Installed Modules"

    echo ""
    echo "MCP Servers:"
    local installed_mcp
    installed_mcp=$(get_installed "mcp")
    if [[ -z "$installed_mcp" ]]; then
        print_info "(none)"
    else
        for m in $installed_mcp; do
            print_success "$m"
        done
    fi

    echo ""
    echo "Skills:"
    local installed_skills
    installed_skills=$(get_installed "skills")
    if [[ -z "$installed_skills" ]]; then
        print_info "(none)"
    else
        for s in $installed_skills; do
            print_success "$s"
        done
    fi

    print_header "Available Modules"

    echo ""
    local name desc
    echo "MCP Servers:"
    for f in "$SCRIPT_DIR/mcp/"*.json; do
        [[ -f "$f" ]] || continue
        name=$(basename "$f" .json)
        desc=$(jq -r '.description' "$f")
        if is_installed "mcp" "$name"; then
            print_info "$name (installed)"
        else
            echo "  [ ] $name - $desc"
        fi
    done

    echo ""
    echo "Skills:"
    for d in "$SCRIPT_DIR/skills/"*/; do
        [[ -d "$d" ]] || continue
        name=$(basename "$d")
        if is_installed "skills" "$name"; then
            print_info "$name (installed)"
        else
            echo "  [ ] $name"
        fi
    done

    # Check for custom modules
    if [[ -d "$CUSTOM_DIR" ]]; then
        print_header "Custom Modules"

        if [[ -d "$CUSTOM_DIR/mcp" ]] && [[ "$(ls -A "$CUSTOM_DIR/mcp" 2>/dev/null)" ]]; then
            echo ""
            echo "Custom MCP Servers:"
            for f in "$CUSTOM_DIR/mcp/"*.json; do
                [[ -f "$f" ]] || continue
                name=$(basename "$f" .json)
                if is_installed "mcp" "custom:$name"; then
                    print_success "$name (installed)"
                else
                    echo "  [ ] $name"
                fi
            done
        fi

        if [[ -d "$CUSTOM_DIR/skills" ]] && [[ "$(ls -A "$CUSTOM_DIR/skills" 2>/dev/null)" ]]; then
            echo ""
            echo "Custom Skills:"
            for d in "$CUSTOM_DIR/skills/"*/; do
                [[ -d "$d" ]] || continue
                name=$(basename "$d")
                if is_installed "skills" "custom:$name"; then
                    print_success "$name (installed)"
                else
                    echo "  [ ] $name"
                fi
            done
        fi
    fi

    echo ""
}

# Select MCP servers interactively
select_mcp() {
    # mode parameter reserved for future use (install vs add)
    SELECTED_MCP=()

    # Skip interactive selection in non-interactive mode
    if [[ "$YES_MODE" = "true" ]]; then
        print_info "MCP servers: skipped (non-interactive mode)"
        return
    fi

    echo ""
    echo "MCP Servers (enter numbers separated by space, or 'none'):"
    echo ""

    local i=1
    local mcps=()
    local name desc

    for f in "$SCRIPT_DIR/mcp/"*.json; do
        [[ -f "$f" ]] || continue
        name=$(basename "$f" .json)
        desc=$(jq -r '.description' "$f")
        if is_installed "mcp" "$name"; then
            echo "     $name [installed]"
        else
            mcps+=("$name")
            echo "  $i) $name - $desc"
            ((i++))
        fi
    done

    # Custom MCP
    if [[ -d "$CUSTOM_DIR/mcp" ]]; then
        for f in "$CUSTOM_DIR/mcp/"*.json; do
            [[ -f "$f" ]] || continue
            name=$(basename "$f" .json)
            desc=$(jq -r '.description' "$f" 2>/dev/null || echo "Custom MCP server")
            if is_installed "mcp" "custom:$name"; then
                echo "     $name (custom) [installed]"
            else
                mcps+=("custom:$name")
                echo "  $i) $name (custom) - $desc"
                ((i++))
            fi
        done
    fi

    if [[ ${#mcps[@]} -eq 0 ]]; then
        echo ""
        echo "  (all MCP servers already installed)"
        return
    fi

    echo ""
    read -rp "Select (e.g., '1 2' or 'none'): " selection

    if [[ "$selection" != "none" ]] && [[ -n "$selection" ]]; then
        for num in $selection; do
            if [[ "$num" -ge 1 ]] && [[ "$num" -le ${#mcps[@]} ]] 2>/dev/null; then
                SELECTED_MCP+=("${mcps[$((num-1))]}")
            fi
        done
    fi
}

# Select skills interactively
select_skills() {
    # mode parameter reserved for future use (install vs add)
    SELECTED_SKILLS=()

    # Skip interactive selection in non-interactive mode
    if [[ "$YES_MODE" = "true" ]]; then
        print_info "Skills: skipped (non-interactive mode)"
        return
    fi

    echo ""
    echo "Skills (enter numbers separated by space, or 'none'):"
    echo ""

    local i=1
    local skills=()
    local name

    for d in "$SCRIPT_DIR/skills/"*/; do
        [[ -d "$d" ]] || continue
        name=$(basename "$d")
        if is_installed "skills" "$name"; then
            echo "     $name [installed]"
        else
            skills+=("$name")
            echo "  $i) $name"
            ((i++))
        fi
    done

    # Custom skills
    if [[ -d "$CUSTOM_DIR/skills" ]]; then
        for d in "$CUSTOM_DIR/skills/"*/; do
            [[ -d "$d" ]] || continue
            name=$(basename "$d")
            if is_installed "skills" "custom:$name"; then
                echo "     $name (custom) [installed]"
            else
                skills+=("custom:$name")
                echo "  $i) $name (custom)"
                ((i++))
            fi
        done
    fi

    if [[ ${#skills[@]} -eq 0 ]]; then
        echo ""
        echo "  (all skills already installed)"
        return
    fi

    echo ""
    read -rp "Select (e.g., '1 2' or 'none'): " selection

    if [[ "$selection" != "none" ]] && [[ -n "$selection" ]]; then
        for num in $selection; do
            if [[ "$num" -ge 1 ]] && [[ "$num" -le ${#skills[@]} ]] 2>/dev/null; then
                SELECTED_SKILLS+=("${skills[$((num-1))]}")
            fi
        done
    fi
}

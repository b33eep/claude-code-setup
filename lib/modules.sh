#!/bin/bash

# Module discovery, listing, and selection

# Global arrays for module selection (used across functions)
SELECTED_MCP=()
SELECTED_SKILLS=()

# ============================================
# INTERACTIVE TOGGLE SELECTION
# ============================================

# Global arrays for interactive_select (Bash 3.2 compatible - no namerefs)
_ISEL_ITEMS=()
_ISEL_DESCS=()
_ISEL_SELECTED=()  # "1" or "0" for each item
_ISEL_MUTUAL=""
_ISEL_ALLOW_ALL=""

# Check if item at index is selected
_isel_is_selected() {
    [[ "${_ISEL_SELECTED[$1]}" = "1" ]]
}

# Toggle selection at index, handling mutual exclusion
_isel_toggle() {
    local idx=$1
    local item="${_ISEL_ITEMS[$idx]}"

    if _isel_is_selected "$idx"; then
        _ISEL_SELECTED[idx]="0"
    else
        # Handle mutual exclusion before selecting
        if [[ -n "$_ISEL_MUTUAL" ]]; then
            local pair a b i other_item
            for pair in $_ISEL_MUTUAL; do
                a="${pair%%:*}"
                b="${pair##*:}"
                if [[ "$item" = "$a" ]] || [[ "$item" = "$b" ]]; then
                    # Find and deselect the other item
                    if [[ "$item" = "$a" ]]; then
                        other_item="$b"
                    else
                        other_item="$a"
                    fi
                    for i in "${!_ISEL_ITEMS[@]}"; do
                        if [[ "${_ISEL_ITEMS[i]}" = "$other_item" ]]; then
                            _ISEL_SELECTED[i]="0"
                            break
                        fi
                    done
                fi
            done
        fi
        _ISEL_SELECTED[idx]="1"
    fi
}

# Select all items
_isel_select_all() {
    local i
    for i in "${!_ISEL_ITEMS[@]}"; do
        _ISEL_SELECTED[i]="1"
    done
}

# Display the selection list
_isel_display() {
    local i marker count=${#_ISEL_ITEMS[@]}
    for i in "${!_ISEL_ITEMS[@]}"; do
        if _isel_is_selected "$i"; then
            marker="[x]"
        else
            marker="[ ]"
        fi
        if [[ -n "${_ISEL_DESCS[$i]:-}" ]]; then
            echo "  $marker $((i+1))) ${_ISEL_ITEMS[$i]} - ${_ISEL_DESCS[$i]}"
        else
            echo "  $marker $((i+1))) ${_ISEL_ITEMS[$i]}"
        fi
    done
    if [[ "$_ISEL_ALLOW_ALL" = "true" ]]; then
        echo "Toggle (1-$count), a=all, Enter to confirm:"
    else
        echo "Toggle (1-$count), Enter to confirm:"
    fi
}

# Redisplay list after toggle (shows updated [x] markers)
_isel_show_status() {
    echo ""
    _isel_display
}

# Interactive toggle selection (Bash 3.2 compatible)
# Sets result in the global array specified by $6
#
# Arguments:
#   $1: space-separated items
#   $2: pipe-separated descriptions (can be empty)
#   $3: space-separated defaults (items to pre-select)
#   $4: mutual_exclusions - space-separated pairs like "a:b c:d"
#   $5: allow_all - "true" to show 'a' option for select all
#   $6: result variable name (SELECTED_MCP or SELECTED_SKILLS)
interactive_select() {
    local items_str=$1
    local descs_str=$2
    local defaults_str=$3
    local mutual_exclusions=$4
    local allow_all=$5
    local result_var=$6

    # Parse items into array
    _ISEL_ITEMS=()
    _ISEL_DESCS=()
    _ISEL_SELECTED=()
    _ISEL_MUTUAL="$mutual_exclusions"
    _ISEL_ALLOW_ALL="$allow_all"

    local item
    for item in $items_str; do
        _ISEL_ITEMS+=("$item")
        _ISEL_SELECTED+=("0")
    done

    local count=${#_ISEL_ITEMS[@]}
    if [[ $count -eq 0 ]]; then
        return
    fi

    # Parse descriptions (pipe-separated to allow spaces)
    if [[ -n "$descs_str" ]]; then
        IFS='|' read -ra _ISEL_DESCS <<< "$descs_str"
    fi

    # Initialize defaults
    local default_item idx
    for default_item in $defaults_str; do
        for idx in "${!_ISEL_ITEMS[@]}"; do
            if [[ "${_ISEL_ITEMS[idx]}" = "$default_item" ]]; then
                _ISEL_SELECTED[idx]="1"
                break
            fi
        done
    done

    # Initial display
    _isel_display

    # Main input loop
    # Use /dev/tty for real terminal, fall back to stdin for expect/tests
    local input num
    local read_source="/dev/tty"
    [[ ! -t 0 ]] && read_source="/dev/stdin"

    while true; do
        if ! IFS= read -r input < "$read_source"; then
            # EOF reached, treat as confirm
            break
        fi

        case "$input" in
            [1-9]|[1-9][0-9])
                # Toggle item by number
                num=$input
                if [[ "$num" -ge 1 ]] && [[ "$num" -le "$count" ]] 2>/dev/null; then
                    _isel_toggle $((num - 1))
                    _isel_show_status
                fi
                ;;
            a|A)
                # Select all (if allowed)
                if [[ "$allow_all" = "true" ]]; then
                    _isel_select_all
                    _isel_show_status
                fi
                ;;
            "")
                # Empty input - confirm selection
                break
                ;;
        esac
    done

    # Build result - set the appropriate global variable
    local result_items=""
    for idx in "${!_ISEL_ITEMS[@]}"; do
        if _isel_is_selected "$idx"; then
            result_items="$result_items ${_ISEL_ITEMS[$idx]}"
        fi
    done

    # Set result to the target array
    if [[ "$result_var" = "SELECTED_MCP" ]]; then
        SELECTED_MCP=()
        for item in $result_items; do
            SELECTED_MCP+=("$item")
        done
    elif [[ "$result_var" = "SELECTED_SKILLS" ]]; then
        SELECTED_SKILLS=()
        for item in $result_items; do
            SELECTED_SKILLS+=("$item")
        done
    else
        echo "Warning: Unknown result variable '$result_var' in interactive_select" >&2
    fi
}

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

    # Build space-separated list of available (not installed) MCP servers
    local mcps_str=""
    local descs_str=""
    local defaults_str=""
    local name desc

    for f in "$SCRIPT_DIR/mcp/"*.json; do
        [[ -f "$f" ]] || continue
        name=$(basename "$f" .json)
        if ! is_installed "mcp" "$name"; then
            desc=$(jq -r '.description' "$f")
            mcps_str="$mcps_str $name"
            # Pipe-separated descriptions
            if [[ -n "$descs_str" ]]; then
                descs_str="$descs_str|$desc"
            else
                descs_str="$desc"
            fi
            # Pre-select only pdf-reader (brave-search requires API key)
            if [[ "$name" = "pdf-reader" ]]; then
                defaults_str="$defaults_str $name"
            fi
        fi
    done

    # Custom MCP
    if [[ -d "$CUSTOM_DIR/mcp" ]]; then
        for f in "$CUSTOM_DIR/mcp/"*.json; do
            [[ -f "$f" ]] || continue
            name=$(basename "$f" .json)
            if ! is_installed "mcp" "custom:$name"; then
                desc=$(jq -r '.description' "$f" 2>/dev/null || echo "Custom MCP server")
                mcps_str="$mcps_str custom:$name"
                if [[ -n "$descs_str" ]]; then
                    descs_str="$descs_str|$desc"
                else
                    descs_str="$desc"
                fi
            fi
        done
    fi

    # Trim leading space
    mcps_str="${mcps_str# }"
    defaults_str="${defaults_str# }"

    if [[ -z "$mcps_str" ]]; then
        echo ""
        echo "  (all MCP servers already installed)"
        return
    fi

    # Show installed servers first
    echo ""
    echo "MCP Servers (toggle with number, Enter to confirm):"
    echo ""

    local installed_shown=false
    for f in "$SCRIPT_DIR/mcp/"*.json; do
        [[ -f "$f" ]] || continue
        name=$(basename "$f" .json)
        if is_installed "mcp" "$name"; then
            echo "     $name [installed]"
            installed_shown=true
        fi
    done
    if [[ -d "$CUSTOM_DIR/mcp" ]]; then
        for f in "$CUSTOM_DIR/mcp/"*.json; do
            [[ -f "$f" ]] || continue
            name=$(basename "$f" .json)
            if is_installed "mcp" "custom:$name"; then
                echo "     $name (custom) [installed]"
                installed_shown=true
            fi
        done
    fi
    if [[ "$installed_shown" = "true" ]]; then
        echo ""
    fi

    # Interactive toggle selection
    # Mutual exclusion: brave-search and google-search
    interactive_select "$mcps_str" "$descs_str" "$defaults_str" "brave-search:google-search" "false" "SELECTED_MCP"
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

    # Build space-separated list of available (not installed) skills
    local skills_str=""
    local descs_str=""
    local name

    for d in "$SCRIPT_DIR/skills/"*/; do
        [[ -d "$d" ]] || continue
        name=$(basename "$d")
        if ! is_installed "skills" "$name"; then
            skills_str="$skills_str $name"
            # Skills don't have descriptions, use empty placeholder
            if [[ -n "$descs_str" ]]; then
                descs_str="$descs_str|"
            fi
        fi
    done

    # Custom skills
    if [[ -d "$CUSTOM_DIR/skills" ]]; then
        for d in "$CUSTOM_DIR/skills/"*/; do
            [[ -d "$d" ]] || continue
            name=$(basename "$d")
            if ! is_installed "skills" "custom:$name"; then
                skills_str="$skills_str custom:$name"
                if [[ -n "$descs_str" ]]; then
                    descs_str="$descs_str|(custom)"
                else
                    descs_str="(custom)"
                fi
            fi
        done
    fi

    # Trim leading space
    skills_str="${skills_str# }"

    if [[ -z "$skills_str" ]]; then
        echo ""
        echo "  (all skills already installed)"
        return
    fi

    # All skills are pre-selected by default
    local defaults_str="$skills_str"

    # Show installed skills first
    echo ""
    echo "Skills (toggle with number, Enter to confirm):"
    echo ""

    local installed_shown=false
    for d in "$SCRIPT_DIR/skills/"*/; do
        [[ -d "$d" ]] || continue
        name=$(basename "$d")
        if is_installed "skills" "$name"; then
            echo "     $name [installed]"
            installed_shown=true
        fi
    done
    if [[ -d "$CUSTOM_DIR/skills" ]]; then
        for d in "$CUSTOM_DIR/skills/"*/; do
            [[ -d "$d" ]] || continue
            name=$(basename "$d")
            if is_installed "skills" "custom:$name"; then
                echo "     $name (custom) [installed]"
                installed_shown=true
            fi
        done
    fi
    if [[ "$installed_shown" = "true" ]]; then
        echo ""
    fi

    # Interactive toggle selection
    # No mutual exclusion, allow "a" for select all
    interactive_select "$skills_str" "$descs_str" "$defaults_str" "" "true" "SELECTED_SKILLS"
}

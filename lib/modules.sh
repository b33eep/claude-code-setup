#!/bin/bash

# Module discovery, listing, and selection

# Global arrays for module selection (used across functions)
SELECTED_MCP=()
SELECTED_SKILLS=()
SELECTED_REMOVE=()

# ============================================
# INTERACTIVE TOGGLE SELECTION
# ============================================

# Global arrays for interactive_select (Bash 3.2 compatible - no namerefs)
_ISEL_ITEMS=()
_ISEL_DESCS=()
_ISEL_SELECTED=()  # "1" or "0" for each item
_ISEL_MUTUAL=""
_ISEL_ALLOW_ALL=""
_ISEL_CURSOR=0     # Current highlighted position for arrow navigation

# ============================================
# CURSOR AND TERMINAL CONTROL
# ============================================

# Hide cursor
_isel_hide_cursor() { tput civis 2>/dev/null || printf '\033[?25l'; }

# Show cursor
_isel_show_cursor() { tput cnorm 2>/dev/null || printf '\033[?25h'; }

# Move cursor up N lines
_isel_cursor_up() { tput cuu "$1" 2>/dev/null || printf '\033[%dA' "$1"; }

# Clear from cursor to end of line
_isel_clear_line() { tput el 2>/dev/null || printf '\033[K'; }

# Clear entire line
_isel_clear_entire_line() { tput el2 2>/dev/null; tput el 2>/dev/null || printf '\033[2K'; }

# Read a single key, handling arrow escape sequences
# Returns: UP, DOWN, SPACE, ENTER, NUM:n, ALL, or OTHER
# Note: Terminal must be in raw mode (set by caller)
_isel_read_key() {
    local key seq

    # Read single character (terminal should already be in raw mode)
    IFS= read -rsn1 key 2>/dev/null || key=""

    # Handle escape sequences (arrow keys)
    if [[ "$key" = $'\033' ]]; then
        # Read the rest of the escape sequence
        read -rsn2 -t 0.1 seq 2>/dev/null || true
        case "$seq" in
            '[A') echo "UP" ;;
            '[B') echo "DOWN" ;;
            *) echo "ESC" ;;
        esac
    elif [[ "$key" = "" ]] || [[ "$key" = $'\n' ]] || [[ "$key" = $'\r' ]]; then
        echo "ENTER"
    elif [[ "$key" = " " ]]; then
        echo "SPACE"
    elif [[ "$key" =~ ^[1-9]$ ]]; then
        echo "NUM:$key"
    elif [[ "$key" = "a" ]] || [[ "$key" = "A" ]]; then
        echo "ALL"
    else
        echo "OTHER"
    fi
}

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

# Display the selection list (fallback mode for tests/pipes)
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

# Display with arrow-key navigation highlighting
_isel_display_interactive() {
    local cursor=$1
    local i marker pointer line
    local cyan='\033[36m'
    local bold='\033[1m'
    local dim='\033[2m'
    local reset='\033[0m'

    for i in "${!_ISEL_ITEMS[@]}"; do
        # Selection marker (filled/empty circle)
        if _isel_is_selected "$i"; then
            marker="${cyan}◉${reset}"
        else
            marker="${dim}○${reset}"
        fi

        # Pointer for current row
        if [[ $i -eq $cursor ]]; then
            pointer="${cyan}❯${reset}"
        else
            pointer=" "
        fi

        # Build line with description
        if [[ -n "${_ISEL_DESCS[$i]:-}" ]]; then
            if [[ $i -eq $cursor ]]; then
                line="${bold}${_ISEL_ITEMS[$i]}${reset} ${dim}- ${_ISEL_DESCS[$i]}${reset}"
            else
                line="${_ISEL_ITEMS[$i]} ${dim}- ${_ISEL_DESCS[$i]}${reset}"
            fi
        else
            if [[ $i -eq $cursor ]]; then
                line="${bold}${_ISEL_ITEMS[$i]}${reset}"
            else
                line="${_ISEL_ITEMS[$i]}"
            fi
        fi

        # Clear line and print
        printf '\033[K'  # Clear to end of line
        printf "  %b %b %b\n" "$pointer" "$marker" "$line"
    done

    # Hint line
    printf '\033[K\n'
    printf '\033[K  %b↑↓%b navigate  %b⎵%b toggle  %b⏎%b confirm\n' \
        "$dim" "$reset" "$dim" "$reset" "$dim" "$reset"
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
    _ISEL_CURSOR=0

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

    # Detect if we have a real TTY for arrow-key navigation
    # Tests use expect which creates a PTY but sends line-based input
    local use_arrows=false
    if [[ -t 0 ]] && [[ -t 1 ]] && [[ -e /dev/tty ]]; then
        # Check if parent process is expect (test scenario)
        local parent_cmd
        parent_cmd=$(ps -o comm= -p $PPID 2>/dev/null) || parent_cmd=""
        if [[ "$parent_cmd" != "expect" ]]; then
            # Not running under expect, safe to use arrow keys
            if (exec 3</dev/tty) 2>/dev/null; then
                exec 3<&-
                use_arrows=true
            fi
        fi
    fi

    # Lines to clear for redraw: items + blank line + hint line
    local lines_to_clear=$((count + 2))

    if [[ "$use_arrows" = true ]]; then
        # Arrow-key navigation mode
        _isel_hide_cursor

        # OS-specific: macOS uses /dev/tty, Linux uses stdin (better for containers)
        local is_macos=false
        [[ "$(uname)" = "Darwin" ]] && is_macos=true

        # Save terminal settings and enable raw mode for single-char reads
        local old_stty
        if [[ "$is_macos" = true ]]; then
            old_stty=$(stty -g </dev/tty 2>/dev/null)
            stty -icanon -echo min 1 </dev/tty 2>/dev/null
            trap '_isel_show_cursor; stty "$old_stty" </dev/tty 2>/dev/null' EXIT INT TERM
        else
            old_stty=$(stty -g 2>/dev/null)
            stty -icanon -echo min 1 2>/dev/null
            trap '_isel_show_cursor; stty "$old_stty" 2>/dev/null' EXIT INT TERM
        fi

        # Initial display
        _isel_display_interactive $_ISEL_CURSOR

        # Main input loop with arrow keys
        local key seq1 seq2 keycode

        while true; do
            # Read single character
            key=""
            if [[ "$is_macos" = true ]]; then
                key=$(dd bs=1 count=1 2>/dev/null </dev/tty) || key=""
            else
                # Linux: read from stdin (already set to raw mode via stty)
                # If read fails and key is empty, just continue (don't treat as Enter)
                if ! IFS= read -rsn1 key 2>/dev/null && [[ -z "$key" ]]; then
                    continue
                fi
            fi
            keycode=$(printf '%d' "'$key" 2>/dev/null) || keycode=0

            # Handle escape sequences (arrow keys) - ESC is ASCII 27
            if [[ "$keycode" = "27" ]]; then
                # Read the rest of the escape sequence (no timeout - chars come immediately)
                if [[ "$is_macos" = true ]]; then
                    seq1=$(dd bs=1 count=1 2>/dev/null </dev/tty) || seq1=""
                    seq2=$(dd bs=1 count=1 2>/dev/null </dev/tty) || seq2=""
                else
                    IFS= read -rsn1 seq1 2>/dev/null || seq1=""
                    IFS= read -rsn1 seq2 2>/dev/null || seq2=""
                fi
                if [[ "$seq1" = "[" ]]; then
                    case "$seq2" in
                        'A') # Up arrow
                            if ((_ISEL_CURSOR > 0)); then
                                _ISEL_CURSOR=$((_ISEL_CURSOR - 1))
                            fi
                            ;;
                        'B') # Down arrow
                            if ((_ISEL_CURSOR < count - 1)); then
                                _ISEL_CURSOR=$((_ISEL_CURSOR + 1))
                            fi
                            ;;
                    esac
                fi
            elif [[ "$key" = $'\n' ]] || [[ "$key" = $'\r' ]]; then
                # Enter - confirm
                break
            elif [[ "$key" = "" ]] && [[ "$keycode" = "0" ]]; then
                # Empty key with code 0 - treat as Enter
                break
            elif [[ "$key" = " " ]]; then
                # Space - toggle current item
                _isel_toggle $_ISEL_CURSOR
            elif [[ "$key" =~ ^[1-9]$ ]]; then
                # Number - toggle by number
                if ((key >= 1 && key <= count)); then
                    _isel_toggle $((key - 1))
                fi
            elif [[ "$key" = "a" ]] || [[ "$key" = "A" ]]; then
                # Select all
                if [[ "$allow_all" = "true" ]]; then
                    _isel_select_all
                fi
            fi

            # Redraw: move cursor up and to start of line, then redraw
            printf '\033[%dA\r' "$lines_to_clear"
            _isel_display_interactive $_ISEL_CURSOR
        done

        # Restore terminal settings
        if [[ "$is_macos" = true ]]; then
            stty "$old_stty" </dev/tty 2>/dev/null
        else
            stty "$old_stty" 2>/dev/null
        fi
        _isel_show_cursor
        trap - EXIT INT TERM
    else
        # Fallback mode for tests/pipes (number-based input)
        _isel_display

        local input num
        local read_source="/dev/stdin"

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
    fi

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
    elif [[ "$result_var" = "SELECTED_EXTERNAL_PLUGINS" ]]; then
        SELECTED_EXTERNAL_PLUGINS=()
        for item in $result_items; do
            SELECTED_EXTERNAL_PLUGINS+=("$item")
        done
    elif [[ "$result_var" = "SELECTED_REMOVE" ]]; then
        SELECTED_REMOVE=()
        for item in $result_items; do
            SELECTED_REMOVE+=("$item")
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

    echo ""
    echo "External Plugins:"
    local installed_plugins
    installed_plugins=$(get_installed "external_plugins")
    if [[ -z "$installed_plugins" ]]; then
        print_info "(none)"
    else
        for p in $installed_plugins; do
            print_success "$p"
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

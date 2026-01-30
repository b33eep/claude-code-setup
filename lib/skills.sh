#!/bin/bash

# Skill installation

# Helper: run install command, adding sudo where needed if not root
run_install_cmd() {
    local full_cmd="$1"
    local is_root=false
    [[ $(id -u) -eq 0 ]] && is_root=true

    # If root, just run as-is
    if [[ "$is_root" == "true" ]]; then
        eval "$full_cmd"
        return $?
    fi

    # Not root: prepend sudo to package manager commands
    # Replace standalone package manager calls with sudo versions
    local modified_cmd="$full_cmd"
    modified_cmd=$(echo "$modified_cmd" | sed -E 's/(^|&& *)(apt-get|apt|dnf|yum|pacman|zypper) /\1sudo \2 /g')

    eval "$modified_cmd"
}

# Install dependencies for a skill from deps.json
# Arguments: $1 = source directory containing deps.json
install_skill_deps() {
    local source_dir=$1
    local deps_file="$source_dir/deps.json"

    # No deps.json = no dependencies
    if [[ ! -f "$deps_file" ]]; then
        return 0
    fi

    local dep_count
    dep_count=$(jq -r '.dependencies | length' "$deps_file")

    if [[ "$dep_count" -eq 0 ]]; then
        return 0
    fi

    echo ""
    echo "  Checking dependencies..."

    local i name check_cmd install_cmd hint
    for ((i=0; i<dep_count; i++)); do
        name=$(jq -r ".dependencies[$i].name" "$deps_file")
        check_cmd=$(jq -r ".dependencies[$i].check" "$deps_file")
        hint=$(jq -r ".dependencies[$i].post_install_hint // empty" "$deps_file")

        # Check if already installed
        if eval "$check_cmd" &>/dev/null; then
            print_info "$name (found)"
            continue
        fi

        # Get platform-specific install command
        local platform_key=""
        case "$OS_TYPE" in
            macos)
                platform_key="macos"
                ;;
            linux)
                platform_key="$LINUX_DISTRO"
                ;;
        esac

        install_cmd=$(jq -r ".dependencies[$i].install.$platform_key // empty" "$deps_file")

        if [[ -z "$install_cmd" ]]; then
            print_warning "$name: no install command for $platform_key"
            print_info "Please install $name manually"
            continue
        fi

        echo "  + $name (installing...)"

        # Execute install command (with sudo if needed and not root)
        if run_install_cmd "$install_cmd"; then
            print_success "$name installed"
            if [[ -n "$hint" ]]; then
                print_info "$hint"
            fi
        else
            print_error "Failed to install $name"
            print_info "Try manually: $install_cmd"
        fi
    done

    return 0
}

# Install a single skill
install_skill() {
    local skill_name=$1
    local source_dir=""
    local name
    local target_dir

    if [[ "$skill_name" == custom:* ]]; then
        name="${skill_name#custom:}"
        source_dir="$CUSTOM_DIR/skills/$name"
    else
        source_dir="$SCRIPT_DIR/skills/$skill_name"
    fi

    if [[ ! -d "$source_dir" ]]; then
        print_error "Skill not found: $source_dir"
        return 1
    fi

    # Install dependencies if deps.json exists
    install_skill_deps "$source_dir"

    target_dir="$CLAUDE_DIR/skills/$(basename "$source_dir")"
    mkdir -p "$CLAUDE_DIR/skills"
    cp -r "$source_dir" "$target_dir"

    return 0
}

# Build CLAUDE.md from template
build_claude_md() {
    local target="$CLAUDE_DIR/CLAUDE.md"
    local template="$SCRIPT_DIR/templates/base/global-CLAUDE.md"
    local user_file="" default_file=""
    local temp_file="" before_file="" after_file=""
    local has_custom_content=false

    # Cleanup function for temp files
    _cleanup_build_temps() {
        rm -f "$user_file" "$default_file" "$temp_file" "$before_file" "$after_file" 2>/dev/null || true
    }

    # Extract user section if exists (between markers)
    if [[ -f "$target" ]]; then
        user_file=$(mktemp)
        default_file=$(mktemp)

        # Extract user's current section
        sed -n '/<!-- USER INSTRUCTIONS START -->/,/<!-- USER INSTRUCTIONS END -->/p' "$target" > "$user_file" 2>/dev/null || true

        # Extract default section from template for comparison
        sed -n '/<!-- USER INSTRUCTIONS START -->/,/<!-- USER INSTRUCTIONS END -->/p' "$template" > "$default_file" 2>/dev/null || true

        # Check if user has custom content (differs from template default)
        if [[ -s "$user_file" ]] && ! diff -q "$user_file" "$default_file" > /dev/null 2>&1; then
            has_custom_content=true
        fi
    fi

    # Copy base template
    cp "$template" "$target"

    # Re-insert preserved user content if we had custom content
    if [[ "$has_custom_content" = true ]] && [[ -f "$user_file" ]]; then
        temp_file=$(mktemp)
        before_file=$(mktemp)
        after_file=$(mktemp)

        # Extract parts: before section, user section (from file), after section
        awk '/<!-- USER INSTRUCTIONS START -->/{exit} {print}' "$target" > "$before_file"
        awk 'p; /<!-- USER INSTRUCTIONS END -->/{p=1}' "$target" > "$after_file"

        # Combine: before + preserved user section + after
        cat "$before_file" > "$temp_file"
        cat "$user_file" >> "$temp_file"
        cat "$after_file" >> "$temp_file"

        mv "$temp_file" "$target"
    fi

    # Cleanup all temp files
    _cleanup_build_temps
}

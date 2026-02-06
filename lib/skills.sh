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
# Set SKIP_SKILL_DEPS=1 to skip (for testing)
install_skill_deps() {
    local source_dir=$1
    local deps_file="$source_dir/deps.json"

    # Skip dependency installation in test mode
    if [[ "${SKIP_SKILL_DEPS:-}" == "1" ]]; then
        return 0
    fi

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

    local i name install_cmd hint
    for ((i=0; i<dep_count; i++)); do
        name=$(jq -r ".dependencies[$i].name" "$deps_file")
        hint=$(jq -r ".dependencies[$i].post_install_hint // empty" "$deps_file")

        # Check if already installed (safe: no eval, just command -v)
        if command -v "$name" &>/dev/null; then
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

# Replace content between marker comments in a file
# Arguments: $1 = file, $2 = marker name (e.g. "MCP_TABLE"), $3 = new content
replace_marker_section() {
    local file="$1" marker_name="$2" content="$3"
    local start_marker="<!-- ${marker_name} START -->"
    local end_marker="<!-- ${marker_name} END -->"
    local tmp_before tmp_after tmp_result

    tmp_before=$(mktemp)
    tmp_after=$(mktemp)
    tmp_result=$(mktemp)

    # Ensure cleanup on any failure
    _cleanup_marker_temps() {
        rm -f "$tmp_before" "$tmp_after" "$tmp_result" 2>/dev/null || true
    }

    # Extract everything before start marker
    awk -v marker="$start_marker" '$0 == marker {exit} {print}' "$file" > "$tmp_before"
    # Extract everything after end marker
    awk -v marker="$end_marker" 'p; $0 == marker {p=1}' "$file" > "$tmp_after"

    # Combine: before + start marker + content + end marker + after
    if ! {
        cat "$tmp_before"
        echo "$start_marker"
        echo "$content"
        echo "$end_marker"
        cat "$tmp_after"
    } > "$tmp_result"; then
        _cleanup_marker_temps
        return 1
    fi

    mv "$tmp_result" "$file"
    rm -f "$tmp_before" "$tmp_after"
}

# Resolve source directory for a module (handles custom: prefix)
# Arguments: $1 = module name, $2 = module type ("mcp" or "skills")
# Outputs: path to source directory/file
_resolve_module_path() {
    local name="$1" type="$2"
    if [[ "$name" == custom:* ]]; then
        echo "$CUSTOM_DIR/$type/${name#custom:}"
    else
        echo "$SCRIPT_DIR/$type/$name"
    fi
}

# Read a frontmatter field from a SKILL.md file
# Arguments: $1 = file path, $2 = field name
# Outputs: field value (raw)
_read_frontmatter() {
    local file="$1" field="$2"
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    # Extract only the first frontmatter block (between first two --- lines)
    awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "$file" | sed -n "s/^${field}: *//p"
}

# Generate MCP Servers table content from installed.json
generate_mcp_table() {
    local modules
    modules=$(get_installed "mcp")

    if [[ -z "$modules" ]]; then
        echo "> No MCP servers installed."
        return
    fi

    echo "| Server | Description |"
    echo "|--------|-------------|"

    local name source_path description
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        source_path="$(_resolve_module_path "$name" "mcp").json"
        description=""
        if [[ -f "$source_path" ]]; then
            description=$(jq -r '.description // ""' "$source_path" 2>/dev/null)
        fi
        local display_name="${name#custom:}"
        echo "| \`${display_name}\` | ${description} |"
    done <<< "$modules"

    echo ""
    echo "> **Note:** Run \`./install.sh --list\` to see installed servers."
}

# Generate Skills table content from installed.json + SKILL.md frontmatter
generate_skills_table() {
    local modules
    modules=$(get_installed "skills")

    if [[ -z "$modules" ]]; then
        echo "> No skills installed."
        return
    fi

    echo "| Skill | Type | Description |"
    echo "|-------|------|-------------|"

    local name source_dir skill_file description skill_type display_name
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        source_dir="$(_resolve_module_path "$name" "skills")"
        skill_file="$source_dir/SKILL.md"
        description=""
        skill_type=""
        if [[ -f "$skill_file" ]]; then
            description=$(_read_frontmatter "$skill_file" "description")
            skill_type=$(_read_frontmatter "$skill_file" "type")
        fi
        display_name="${name#custom:}"
        echo "| \`${display_name}\` | ${skill_type} | ${description} |"
    done <<< "$modules"

    echo ""
    echo "**Skill Types:**"
    echo "- \`command\`: Invoked explicitly via \`/skill-name\`"
    echo "- \`context\`: Auto-loaded based on Tech Stack AND task"
    echo ""
    echo "> **Note:** Run \`./install.sh --list\` to see installed skills."
}

# Generate Skill Loading table content from installed context skills
generate_skill_loading_table() {
    local modules
    modules=$(get_installed "skills")

    local has_entries=false
    local rows=""

    local name source_dir skill_file skill_type extensions display_name
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        source_dir="$(_resolve_module_path "$name" "skills")"
        skill_file="$source_dir/SKILL.md"

        # Only context skills have file extension mappings
        skill_type=""
        if [[ -f "$skill_file" ]]; then
            skill_type=$(_read_frontmatter "$skill_file" "type")
        fi
        [[ "$skill_type" != "context" ]] && continue

        # Read file_extensions from frontmatter
        extensions=""
        if [[ -f "$skill_file" ]]; then
            extensions=$(_read_frontmatter "$skill_file" "file_extensions")
        fi

        # Fallback: hardcoded lookup for skills without file_extensions field
        if [[ -z "$extensions" ]]; then
            extensions=$(_get_fallback_extensions "$name")
        fi
        [[ -z "$extensions" ]] && continue

        display_name="${name#custom:}"
        # Convert [".py", ".pyi"] to `.py`, `.pyi` (backticks are literal markdown)
        local formatted_exts bt='`'
        formatted_exts=$(echo "$extensions" | tr -d '[]"' | sed "s/,  */${bt}, ${bt}/g; s/^/${bt}/; s/$/${bt}/")

        rows+="| ${formatted_exts} | \`~/.claude/skills/${display_name}/SKILL.md\` |"$'\n'
        has_entries=true
    done <<< "$modules"

    if [[ "$has_entries" != true ]]; then
        echo "> No context skills installed."
        return
    fi

    echo "| File Extension | Skill to Load |"
    echo "|----------------|---------------|"
    printf "%s" "$rows"
}

# Fallback file extensions for skills without file_extensions in frontmatter
_get_fallback_extensions() {
    local name="${1#custom:}"
    case "$name" in
        standards-python)       echo '[".py"]' ;;
        standards-javascript)   echo '[".js", ".mjs", ".cjs"]' ;;
        standards-typescript)   echo '[".ts", ".tsx", ".jsx"]' ;;
        standards-shell)        echo '[".sh", ".bash"]' ;;
        standards-java)         echo '[".java"]' ;;
        standards-kotlin)       echo '[".kt", ".kts"]' ;;
        standards-gradle)       echo '[".gradle.kts", ".gradle"]' ;;
        *)                      echo "" ;;
    esac
}

# Build CLAUDE.md from template with dynamic table generation
build_claude_md() {
    local target="$CLAUDE_DIR/CLAUDE.md"
    local template="$SCRIPT_DIR/templates/base/global-CLAUDE.md"
    local user_content="" has_custom_content=false

    # Preserve user instructions from existing file
    if [[ -f "$target" ]]; then
        local user_file default_file
        user_file=$(mktemp)
        default_file=$(mktemp)

        # Extract content between markers (exclusive — without the marker lines themselves)
        sed -n '/<!-- USER INSTRUCTIONS START -->/,/<!-- USER INSTRUCTIONS END -->/{//!p;}' "$target" > "$user_file" 2>/dev/null || true
        sed -n '/<!-- USER INSTRUCTIONS START -->/,/<!-- USER INSTRUCTIONS END -->/{//!p;}' "$template" > "$default_file" 2>/dev/null || true

        if [[ -s "$user_file" ]] && ! diff -q "$user_file" "$default_file" > /dev/null 2>&1; then
            has_custom_content=true
            user_content=$(cat "$user_file")
        fi

        rm -f "$user_file" "$default_file"
    fi

    # Start from template (atomic: work on temp file)
    local work_file
    work_file=$(mktemp)
    cp "$template" "$work_file"

    # Generate dynamic table content
    local mcp_content skills_content loading_content
    mcp_content=$(generate_mcp_table)
    skills_content=$(generate_skills_table)
    loading_content=$(generate_skill_loading_table)

    # Replace marker sections with generated content
    replace_marker_section "$work_file" "MCP_TABLE" "$mcp_content"
    replace_marker_section "$work_file" "SKILLS_TABLE" "$skills_content"
    replace_marker_section "$work_file" "SKILL_LOADING_TABLE" "$loading_content"

    # Re-insert preserved user instructions
    if [[ "$has_custom_content" = true ]]; then
        replace_marker_section "$work_file" "USER INSTRUCTIONS" "$user_content"
    fi

    # Atomic: move completed file to target
    mv "$work_file" "$target"
}

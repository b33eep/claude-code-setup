#!/bin/bash

# Helper functions: colors, printing, JSON utilities

# ============================================
# TTY-AWARE INPUT
# ============================================

# Read user input, using /dev/tty if stdin is not a terminal (e.g., pipe install)
# Usage: result=$(read_input "prompt") || handle_no_tty
# Returns: echoes the input value; returns 1 if no TTY available
#
# Priority:
# 1. If stdin is a terminal → read from stdin
# 2. If stdin has data (pipe) → read from stdin (enables: printf '1\n' | ./install.sh for tests)
# 3. Otherwise → return 1 (non-interactive, triggers --yes fallback)
#
# Note: We don't use /dev/tty because it's unreliable with curl | bash on macOS.
# For interactive pipe install, use: bash <(curl -fsSL url) instead of curl | bash
read_input() {
    local prompt=$1
    local result=""

    if [[ -t 0 ]]; then
        # stdin is a terminal, read normally
        read -rp "$prompt" result
        printf '%s' "$result"
    elif [[ ! -t 0 ]]; then
        # stdin is a pipe with data (for tests: printf '1\n' | ./install.sh)
        # Show prompt on stderr so user sees it, read from stdin pipe
        printf '%s' "$prompt" >&2
        if read -r result; then
            printf '%s' "$result"
        else
            return 1
        fi
    else
        # No TTY available, can't prompt interactively
        return 1
    fi
}


# ============================================
# COLORS
# ============================================

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Print functions
print_header() {
    echo ""
    echo -e "${BLUE}$1${NC}"
    printf '%*s\n' "${#1}" '' | tr ' ' '-'
}

print_success() {
    echo -e "  ${GREEN}+${NC} $1"
}

print_info() {
    echo -e "  ${BLUE}-${NC} $1"
}

print_warning() {
    echo -e "  ${YELLOW}!${NC} $1" >&2
}

print_error() {
    echo -e "  ${RED}x${NC} $1" >&2
}

# JSON utilities

# Initialize installed.json if it doesn't exist
init_installed_json() {
    mkdir -p "$CLAUDE_DIR"
    if [[ ! -f "$INSTALLED_FILE" ]]; then
        echo "{\"content_version\":$(get_content_version),\"mcp\":[],\"skills\":[],\"scripts\":[],\"command_overrides\":[]}" > "$INSTALLED_FILE"
    fi
    # Ensure new arrays exist (migration for existing installs)
    if ! jq -e '.command_overrides' "$INSTALLED_FILE" > /dev/null 2>&1; then
        jq '.command_overrides = []' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp" && mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"
    fi
    if ! jq -e '.scripts' "$INSTALLED_FILE" > /dev/null 2>&1; then
        jq '.scripts = []' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp" && mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"
    fi
}

# Check if a module is installed
is_installed() {
    local category=$1
    local module=$2

    # Check installed.json first
    if jq -e ".${category} | index(\"${module}\")" "$INSTALLED_FILE" > /dev/null 2>&1; then
        return 0
    fi

    # For MCP, also check .claude.json (may have been installed before tracking)
    if [[ "$category" = "mcp" ]] && [[ -f "$MCP_CONFIG_FILE" ]]; then
        jq -e ".mcpServers[\"${module}\"]" "$MCP_CONFIG_FILE" > /dev/null 2>&1
        return $?
    fi

    # For skills, also check filesystem (may have been installed before tracking)
    if [[ "$category" = "skills" ]]; then
        local skill_name="${module#custom:}"
        [[ -d "$CLAUDE_DIR/skills/$skill_name" ]]
        return $?
    fi

    return 1
}

# Check if module is tracked in installed.json (not filesystem)
is_tracked() {
    local category=$1
    local module=$2
    jq -e ".${category} | index(\"${module}\")" "$INSTALLED_FILE" > /dev/null 2>&1
}

# Add module to installed list
add_to_installed() {
    local category=$1
    local module=$2

    if ! is_tracked "$category" "$module"; then
        jq ".${category} += [\"${module}\"]" "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp" && mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"
    fi
}

# Get installed modules
get_installed() {
    local category=$1
    jq -r ".${category}[]" "$INSTALLED_FILE" 2>/dev/null || echo ""
}

# Get available content version from templates/VERSION
get_content_version() {
    cat "$CONTENT_VERSION_FILE" 2>/dev/null || echo "1"
}

# Get installed content version from .installed.json
get_installed_content_version() {
    jq -r '.content_version // 0' "$INSTALLED_FILE" 2>/dev/null || echo "0"
}

# Set installed content version
set_installed_content_version() {
    local version=$1
    jq ".content_version = $version" "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp" && mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"
}

# Reconcile tracking with filesystem
# Ensures installed.json reflects what's actually installed on disk
# Call this during --update to fix tracking for modules installed before tracking existed
reconcile_tracking() {
    local name

    # Reconcile MCP: check .claude.json for servers not tracked in installed.json
    if [[ -f "$MCP_CONFIG_FILE" ]]; then
        while IFS= read -r name; do
            [[ -n "$name" ]] || continue
            if ! is_tracked "mcp" "$name"; then
                add_to_installed "mcp" "$name"
                print_info "Tracking recovered: $name (MCP)"
            fi
        done < <(jq -r '.mcpServers | keys[]' "$MCP_CONFIG_FILE" 2>/dev/null)
    fi

    # Reconcile skills: check ~/.claude/skills/ for skills not tracked in installed.json
    if [[ -d "$CLAUDE_DIR/skills" ]]; then
        for d in "$CLAUDE_DIR/skills/"*/; do
            [[ -d "$d" ]] || continue
            name=$(basename "$d")
            # Only track if it has SKILL.md (is a real skill, not assets/references)
            [[ -f "$d/SKILL.md" ]] || continue
            if ! is_tracked "skills" "$name"; then
                add_to_installed "skills" "$name"
                print_info "Tracking recovered: $name (skill)"
            fi
        done
    fi
}

# Install custom scripts from custom repo to ~/.claude/scripts/
# Copies files from $CUSTOM_DIR/scripts/ to $CLAUDE_DIR/scripts/ with +x permissions
# Tracks installed scripts in installed.json
# Returns 0 if scripts were installed, 1 if no scripts found
install_custom_scripts() {
    if [[ ! -d "$CUSTOM_DIR/scripts" ]]; then
        return 1
    fi

    local has_scripts=false
    local script
    for script in "$CUSTOM_DIR/scripts/"*; do
        [[ -f "$script" ]] || continue
        has_scripts=true
        break
    done

    if [[ "$has_scripts" = false ]]; then
        return 1
    fi

    print_header "Installing Custom Scripts"
    mkdir -p "$CLAUDE_DIR/scripts"

    local filename
    for script in "$CUSTOM_DIR/scripts/"*; do
        [[ -f "$script" ]] || continue
        filename=$(basename "$script")
        cp "$script" "$CLAUDE_DIR/scripts/"
        chmod +x "$CLAUDE_DIR/scripts/$filename"
        add_to_installed "scripts" "$filename"
        print_success "$filename"
    done

    return 0
}

# Merge a custom command file, replacing {{base:name}} markers with base content
# $1: custom command file path
# $2: base commands directory (where base .md files live)
# Outputs merged content to stdout
merge_command() {
    local custom_file=$1
    local base_dir=$2
    local line base_name base_file marker

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Process all {{base:name}} markers in this line
        while [[ "$line" == *'{{base:'*'}}'* ]]; do
            # Extract base name from first marker
            local tmp="${line#*\{\{base:}"
            base_name="${tmp%%\}\}*}"
            marker="{{base:${base_name}}}"

            # Validate base name (prevent empty and path traversal)
            local warn_msg
            if [[ -z "$base_name" ]]; then
                print_warning "Empty base command name in marker"
                warn_msg="<!-- WARNING: empty base command name -->"
                line="${line/"$marker"/$warn_msg}"
                continue
            fi
            if [[ ! "$base_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                print_warning "Invalid base command name: '$base_name'"
                warn_msg="<!-- WARNING: invalid base command name ${base_name} -->"
                line="${line/"$marker"/$warn_msg}"
                continue
            fi

            base_file="$base_dir/$base_name.md"
            if [[ -f "$base_file" ]] && [[ -r "$base_file" ]]; then
                local base_content
                base_content=$(<"$base_file") || {
                    print_warning "Failed to read base command: '$base_name'"
                    warn_msg="<!-- WARNING: failed to read base command ${base_name} -->"
                    line="${line/"$marker"/$warn_msg}"
                    continue
                }
                line="${line/"$marker"/$base_content}"
            else
                print_warning "Base command not found: '$base_name'"
                warn_msg="<!-- WARNING: base command ${base_name} not found -->"
                line="${line/"$marker"/$warn_msg}"
            fi
        done
        printf '%s\n' "$line"
    done < "$custom_file"
}

# Install custom commands from custom repo (override or extend base commands)
# Override mode: custom command without {{base:...}} marker replaces base entirely
# Extend mode: custom command with {{base:name}} marker merges with base content
# Tracks installed overrides in installed.json
# Returns 0 if commands were installed, 1 if no custom commands found
install_custom_commands() {
    if [[ ! -d "$CUSTOM_DIR/commands" ]]; then
        return 1
    fi

    local has_commands=false
    local cmd
    for cmd in "$CUSTOM_DIR/commands/"*.md; do
        [[ -f "$cmd" ]] || continue
        has_commands=true
        break
    done

    if [[ "$has_commands" = false ]]; then
        return 1
    fi

    print_header "Installing Custom Commands"

    local filename
    for cmd in "$CUSTOM_DIR/commands/"*.md; do
        [[ -f "$cmd" ]] || continue
        filename=$(basename "$cmd")

        if grep -q '{{base:' "$cmd" 2>/dev/null; then
            # Extend mode: merge with base
            merge_command "$cmd" "$SCRIPT_DIR/commands" > "$CLAUDE_DIR/commands/$filename"
            add_to_installed "command_overrides" "$filename"
            print_success "$filename (extended)"
        else
            # Override mode: replace base entirely
            cp "$cmd" "$CLAUDE_DIR/commands/$filename"
            add_to_installed "command_overrides" "$filename"
            print_success "$filename (override)"
        fi
    done

    return 0
}

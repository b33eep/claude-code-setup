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
# 2. If /dev/tty is available and works → read from /dev/tty (enables: curl | bash)
# 3. If stdin has data (pipe) → read from stdin (enables: printf '1\n' | ./install.sh for tests)
# 4. Otherwise → return 1 (non-interactive)
read_input() {
    local prompt=$1
    local result

    if [[ -t 0 ]]; then
        # stdin is a terminal, read normally
        read -rp "$prompt" result
        printf '%s' "$result"
    elif [[ -r /dev/tty ]] && { : < /dev/tty; } 2>/dev/null; then
        # stdin is not a terminal (pipe), but /dev/tty is usable
        # This enables interactivity for: curl ... | bash
        read -rp "$prompt" result < /dev/tty
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
        echo "{\"content_version\":$(get_content_version),\"mcp\":[],\"skills\":[]}" > "$INSTALLED_FILE"
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

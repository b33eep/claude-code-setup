#!/bin/bash

# Claude Code Setup Installer
# Modular installation with support for custom modules
# Supports macOS and Linux (Ubuntu/Debian, Arch, Fedora)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Paths - can be overridden via environment for testing
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
CUSTOM_DIR="${CUSTOM_DIR:-$CLAUDE_DIR/custom}"
INSTALLED_FILE="${INSTALLED_FILE:-$CLAUDE_DIR/installed.json}"
MCP_CONFIG_FILE="${MCP_CONFIG_FILE:-$HOME/.claude.json}"
CONTENT_VERSION_FILE="${CONTENT_VERSION_FILE:-$SCRIPT_DIR/templates/VERSION}"
CCSTATUS_CONFIG_DIR="${CCSTATUS_CONFIG_DIR:-$HOME/.config/ccstatusline}"

# Non-interactive mode (--yes flag)
YES_MODE=false

# Source library modules
# shellcheck source=lib/platform.sh
source "$SCRIPT_DIR/lib/platform.sh"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"
# shellcheck source=lib/modules.sh
source "$SCRIPT_DIR/lib/modules.sh"
# shellcheck source=lib/mcp.sh
source "$SCRIPT_DIR/lib/mcp.sh"
# shellcheck source=lib/skills.sh
source "$SCRIPT_DIR/lib/skills.sh"
# shellcheck source=lib/statusline.sh
source "$SCRIPT_DIR/lib/statusline.sh"
# shellcheck source=lib/update.sh
source "$SCRIPT_DIR/lib/update.sh"

# Cleanup handler for temp files and interrupts
cleanup() {
    rm -f "$INSTALLED_FILE.tmp" "$MCP_CONFIG_FILE.tmp" "$CLAUDE_DIR/settings.json.tmp" 2>/dev/null || true
}
trap cleanup EXIT
trap 'echo ""; echo "Installation cancelled."; exit 130' INT TERM

# ============================================
# USAGE
# ============================================

show_usage() {
    echo "Claude Code Setup Installer"
    echo ""
    echo "Usage: ./install.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  (none)      Initial installation with interactive wizard"
    echo "  --add       Add more modules to existing installation"
    echo "  --update    Update all installed modules"
    echo "  --yes, -y   Skip confirmation prompts (for --update)"
    echo "  --list      Show installed and available modules"
    echo "  --version   Show content version"
    echo "  --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./install.sh --update --yes   Non-interactive update"
    echo ""
    echo "Custom Modules:"
    echo "  Place custom modules in ~/.claude/custom/"
    echo "  Structure: custom/{mcp,skills}/"
    echo ""
    echo "Supported Platforms:"
    echo "  - macOS (Homebrew)"
    echo "  - Ubuntu/Debian (apt)"
    echo "  - Arch/Manjaro (pacman)"
    echo "  - Fedora/RHEL (dnf)"
    echo ""
}

show_version() {
    local available_v
    local installed_v
    available_v=$(get_content_version)

    echo "Claude Code Setup"
    echo ""
    echo "Content version: v$available_v"

    if [[ -f "$INSTALLED_FILE" ]]; then
        installed_v=$(get_installed_content_version)
        if [[ "$installed_v" -eq "$available_v" ]]; then
            echo "Installed: v$installed_v (up to date)"
        else
            echo "Installed: v$installed_v (update available)"
        fi
    else
        echo "Installed: (not installed)"
    fi
    echo ""
}

# ============================================
# MAIN INSTALLATION
# ============================================

do_install() {
    local mode=$1  # "install" or "add"

    if [[ "$mode" = "install" ]]; then
        echo ""
        echo "Claude Code Setup Installer"
        echo "============================"
    else
        echo ""
        echo "Claude Code Setup - Add Modules"
        echo "================================"
    fi

    # Detect OS and check dependencies
    print_header "Dependencies"

    detect_os
    print_info "OS: $(get_os_display_name)"

    check_package_manager

    install_jq

    # Create directories
    mkdir -p "$CLAUDE_DIR"
    mkdir -p "$CLAUDE_DIR/commands"
    mkdir -p "$CLAUDE_DIR/skills"
    mkdir -p "$CLAUDE_DIR/templates"
    mkdir -p "$CUSTOM_DIR/mcp"
    mkdir -p "$CUSTOM_DIR/skills"

    init_installed_json

    # Select modules
    print_header "Select Modules"

    select_mcp "$mode"
    select_skills "$mode"

    # Install commands (always)
    print_header "Installing Commands"

    local filename
    for cmd in "$SCRIPT_DIR/commands/"*.md; do
        [[ -f "$cmd" ]] || continue
        filename=$(basename "$cmd")
        cp "$cmd" "$CLAUDE_DIR/commands/"
        print_success "$filename"
    done

    # Build CLAUDE.md
    print_header "Building CLAUDE.md"

    build_claude_md
    print_success "CLAUDE.md created"

    # Install project template
    cp "$SCRIPT_DIR/templates/project-CLAUDE.md" "$CLAUDE_DIR/templates/CLAUDE.template.md"
    print_success "Project template installed"

    # Install MCP servers
    local display_name
    if [[ ${#SELECTED_MCP[@]} -gt 0 ]]; then
        print_header "Installing MCP Servers"

        for mcp in "${SELECTED_MCP[@]}"; do
            display_name="${mcp#custom:}"
            echo ""
            echo "  Installing $display_name..."
            if install_mcp "$mcp"; then
                add_to_installed "mcp" "$mcp"
                print_success "$display_name configured"
            fi
        done
    fi

    # Install skills
    if [[ ${#SELECTED_SKILLS[@]} -gt 0 ]]; then
        print_header "Installing Skills"

        for skill in "${SELECTED_SKILLS[@]}"; do
            display_name="${skill#custom:}"
            if install_skill "$skill"; then
                add_to_installed "skills" "$skill"
                print_success "$display_name installed"
            fi
        done
    fi

    # Configure status line
    print_header "Status Line"
    configure_statusline

    # Done
    print_header "Installation Complete"

    echo ""
    echo "Installed to:"
    echo "  ~/.claude/CLAUDE.md"
    echo "  ~/.claude/commands/"
    echo "  ~/.claude/skills/"
    echo "  ~/.claude/settings.json (user settings)"
    echo "  ~/.claude.json (MCP configuration)"
    echo ""
    echo "Next steps:"
    echo "  1. New project: Run /init-project to set up CLAUDE.md"
    echo "  2. After session: Run /clear-session to document and commit"
    echo ""
    echo "Commands:"
    echo "  ./install.sh --add     Add more modules"
    echo "  ./install.sh --update  Update installed modules"
    echo "  ./install.sh --list    Show all modules"
    echo ""
}

# ============================================
# MAIN
# ============================================

main() {
    local action=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                show_usage
                return 0
                ;;
            --version|-v)
                show_version
                return 0
                ;;
            --list|-l)
                action="list"
                ;;
            --add|-a)
                action="add"
                ;;
            --update|-u)
                action="update"
                ;;
            --yes|-y)
                YES_MODE=true
                ;;
            *)
                echo "Unknown option: $1" >&2
                show_usage
                exit 1
                ;;
        esac
        shift
    done

    # Execute action
    case "$action" in
        "list")
            init_installed_json
            list_modules
            ;;
        "add")
            do_install "add"
            ;;
        "update")
            do_update
            ;;
        "")
            if [[ -f "$INSTALLED_FILE" ]]; then
                echo ""
                echo "Existing installation detected."
                echo "Use --add to add modules or --update to update."
                echo ""
                local confirm
                if confirm=$(read_input "Continue with fresh install? (y/N): "); then
                    if [[ "$confirm" != "y" ]] && [[ "$confirm" != "Y" ]]; then
                        echo "Cancelled."
                        exit 0
                    fi
                else
                    echo "Non-interactive environment detected. Use --yes to force."
                    exit 1
                fi
                # Reset installed.json for fresh install
                echo "{\"content_version\":$(get_content_version),\"mcp\":[],\"skills\":[]}" > "$INSTALLED_FILE"
            fi
            do_install "install"
            ;;
    esac
}

main "$@"

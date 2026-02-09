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
# shellcheck source=lib/external-plugins.sh
source "$SCRIPT_DIR/lib/external-plugins.sh"
# shellcheck source=lib/uninstall.sh
source "$SCRIPT_DIR/lib/uninstall.sh"
# shellcheck source=lib/hooks.sh
source "$SCRIPT_DIR/lib/hooks.sh"
# shellcheck source=lib/agent-teams.sh
source "$SCRIPT_DIR/lib/agent-teams.sh"

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
    echo "  --remove    Remove installed modules"
    echo "  --update    Update all installed modules"
    echo "  --yes, -y   Skip confirmation prompts (for --update)"
    echo "  --list      Show installed and available modules"
    echo "  --version   Show content version"
    echo "  --help      Show this help message"
    echo ""
    echo "Direct Installation (non-interactive):"
    echo "  --add-skill <name>      Install a specific skill by name"
    echo "  --add-mcp <name>        Install a specific MCP server by name"
    echo "  --remove-skill <name>   Remove a specific skill by name"
    echo "  --remove-mcp <name>     Remove a specific MCP server by name"
    echo ""
    echo "Examples:"
    echo "  ./install.sh --update --yes        Non-interactive update"
    echo "  ./install.sh --add-skill standards-kotlin"
    echo "  ./install.sh --add-mcp brave-search"
    echo "  ./install.sh --remove-skill standards-kotlin"
    echo "  ./install.sh --remove-mcp brave-search"
    echo "  ./install.sh --remove              Remove installed modules"
    echo ""
    echo "Custom Modules:"
    echo "  Place custom modules in ~/.claude/custom/"
    echo "  Structure: custom/{mcp,skills}/"
    echo "  Reference custom modules with 'custom:' prefix:"
    echo "    ./install.sh --add-skill custom:my-skill"
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
    select_external_plugins "$mode"

    # Install commands (always)
    print_header "Installing Commands"

    local filename
    for cmd in "$SCRIPT_DIR/commands/"*.md; do
        [[ -f "$cmd" ]] || continue
        filename=$(basename "$cmd")
        cp "$cmd" "$CLAUDE_DIR/commands/"
        print_success "$filename"
    done

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

    # Install external plugins
    install_external_plugins

    # Build CLAUDE.md with dynamic tables (after all modules are installed)
    print_header "Building CLAUDE.md"
    build_claude_md
    print_success "CLAUDE.md created"

    # Configure status line
    print_header "Status Line"
    configure_statusline

    # Configure hooks
    print_header "Hooks"
    configure_hooks

    # Configure Agent Teams
    print_header "Agent Teams"
    configure_agent_teams

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
    echo "  2. After session: Run /wrapup to document and commit"
    echo ""
    # Show different commands based on install method
    if [[ "${QUICK_INSTALL:-}" == "true" ]]; then
        echo "Manage installation (in Claude session):"
        echo "  /claude-code-setup  Update or add more modules"
    else
        echo "Commands:"
        echo "  ./install.sh --add     Add more modules"
        echo "  ./install.sh --update  Update installed modules"
        echo "  ./install.sh --list    Show all modules"
    fi
    echo ""
}

# ============================================
# DIRECT INSTALLATION (non-interactive)
# ============================================

# Install a single skill by name
# Usage: do_add_skill <skill_name>
# skill_name can be "skill-name" or "custom:skill-name"
do_add_skill() {
    local skill_name=$1

    echo ""
    echo "Claude Code Setup - Add Skill"
    echo "=============================="

    # Check dependencies
    detect_os
    check_package_manager
    install_jq

    # Initialize
    mkdir -p "$CLAUDE_DIR/skills"
    init_installed_json

    # Check if already installed
    if is_installed "skills" "$skill_name"; then
        print_warning "Skill '$skill_name' is already installed"
        return 0
    fi

    # Determine source directory
    local source_dir=""
    local display_name=""
    if [[ "$skill_name" == custom:* ]]; then
        local name="${skill_name#custom:}"
        source_dir="$CUSTOM_DIR/skills/$name"
        display_name="$name (custom)"
    else
        source_dir="$SCRIPT_DIR/skills/$skill_name"
        display_name="$skill_name"
    fi

    # Check if skill exists
    if [[ ! -d "$source_dir" ]]; then
        print_error "Skill not found: $skill_name"
        echo ""
        echo "Available skills:"
        for d in "$SCRIPT_DIR/skills/"*/; do
            [[ -d "$d" ]] && echo "  - $(basename "$d")"
        done
        if [[ -d "$CUSTOM_DIR/skills" ]]; then
            for d in "$CUSTOM_DIR/skills/"*/; do
                [[ -d "$d" ]] && echo "  - custom:$(basename "$d")"
            done
        fi
        return 1
    fi

    # Install skill
    print_header "Installing Skill: $display_name"

    if install_skill "$skill_name"; then
        add_to_installed "skills" "$skill_name"
        print_success "$display_name installed"
    else
        print_error "Failed to install $display_name"
        return 1
    fi

    # Rebuild CLAUDE.md with new skill
    print_header "Rebuilding CLAUDE.md"
    build_claude_md
    print_success "CLAUDE.md updated"

    echo ""
    print_success "Done! Skill '$display_name' is now available."
    echo ""
}

# Install a single MCP server by name
# Usage: do_add_mcp <mcp_name>
# mcp_name can be "mcp-name" or "custom:mcp-name"
do_add_mcp() {
    local mcp_name=$1

    echo ""
    echo "Claude Code Setup - Add MCP Server"
    echo "==================================="

    # Check dependencies
    detect_os
    check_package_manager
    install_jq

    # Initialize
    init_installed_json

    # Check if already installed
    if is_installed "mcp" "$mcp_name"; then
        print_warning "MCP server '$mcp_name' is already installed"
        return 0
    fi

    # Determine source file
    local source_file=""
    local display_name=""
    if [[ "$mcp_name" == custom:* ]]; then
        local name="${mcp_name#custom:}"
        source_file="$CUSTOM_DIR/mcp/$name.json"
        display_name="$name (custom)"
    else
        source_file="$SCRIPT_DIR/mcp/$mcp_name.json"
        display_name="$mcp_name"
    fi

    # Check if MCP exists
    if [[ ! -f "$source_file" ]]; then
        print_error "MCP server not found: $mcp_name"
        echo ""
        echo "Available MCP servers:"
        for f in "$SCRIPT_DIR/mcp/"*.json; do
            [[ -f "$f" ]] && echo "  - $(basename "$f" .json)"
        done
        if [[ -d "$CUSTOM_DIR/mcp" ]]; then
            for f in "$CUSTOM_DIR/mcp/"*.json; do
                [[ -f "$f" ]] && echo "  - custom:$(basename "$f" .json)"
            done
        fi
        return 1
    fi

    # Install MCP
    print_header "Installing MCP: $display_name"

    if install_mcp "$mcp_name"; then
        add_to_installed "mcp" "$mcp_name"
        print_success "$display_name configured"
    else
        print_error "Failed to install $display_name"
        return 1
    fi

    # Rebuild CLAUDE.md with new MCP
    print_header "Rebuilding CLAUDE.md"
    build_claude_md
    print_success "CLAUDE.md updated"

    echo ""
    print_success "Done! MCP server '$display_name' is now configured."
    echo ""
    echo "⚠️  IMPORTANT: Restart Claude Code to activate the new MCP server."
    echo ""
}

# ============================================
# DIRECT REMOVAL (non-interactive)
# ============================================

# Remove a single skill by name
# Usage: do_remove_skill <skill_name>
# skill_name can be "skill-name" or "custom:skill-name"
do_remove_skill() {
    local skill_name=$1

    echo ""
    echo "Claude Code Setup - Remove Skill"
    echo "================================="

    # Check dependencies
    detect_os
    check_package_manager
    install_jq

    # Check for installed.json
    if [[ ! -f "$INSTALLED_FILE" ]]; then
        print_error "No installation found. Nothing to remove."
        return 1
    fi

    # Check if skill is installed (tracking or filesystem)
    local display_name="${skill_name#custom:}"
    if ! is_installed "skills" "$skill_name"; then
        print_warning "Skill '$skill_name' is not installed"
        return 0
    fi

    # Remove skill
    print_header "Removing Skill: $display_name"

    if uninstall_skill "$skill_name"; then
        print_success "$display_name removed"
    else
        print_error "Failed to remove $display_name"
        return 1
    fi

    # Rebuild CLAUDE.md without removed skill
    print_header "Rebuilding CLAUDE.md"
    build_claude_md
    print_success "CLAUDE.md updated"

    echo ""
    print_success "Done! Skill '$display_name' has been removed."
    echo ""
}

# Remove a single MCP server by name
# Usage: do_remove_mcp <mcp_name>
# mcp_name can be "mcp-name" or "custom:mcp-name"
do_remove_mcp() {
    local mcp_name=$1

    echo ""
    echo "Claude Code Setup - Remove MCP Server"
    echo "======================================="

    # Check dependencies
    detect_os
    check_package_manager
    install_jq

    # Check for installed.json
    if [[ ! -f "$INSTALLED_FILE" ]]; then
        print_error "No installation found. Nothing to remove."
        return 1
    fi

    # Check if MCP is installed (tracking or filesystem)
    local display_name="${mcp_name#custom:}"
    if ! is_installed "mcp" "$mcp_name"; then
        print_warning "MCP server '$mcp_name' is not installed"
        return 0
    fi

    # Remove MCP
    print_header "Removing MCP: $display_name"

    if uninstall_mcp "$mcp_name"; then
        print_success "$display_name removed"
    else
        print_error "Failed to remove $display_name"
        return 1
    fi

    # Rebuild CLAUDE.md without removed MCP
    print_header "Rebuilding CLAUDE.md"
    build_claude_md
    print_success "CLAUDE.md updated"

    echo ""
    print_success "Done! MCP server '$display_name' has been removed."
    echo ""
    echo "IMPORTANT: Restart Claude Code to deactivate the removed MCP server."
    echo ""
}

# ============================================
# MAIN
# ============================================

main() {
    local action=""
    local add_skill_name=""
    local add_mcp_name=""
    local remove_skill_name=""
    local remove_mcp_name=""

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
            --add-skill)
                action="add-skill"
                shift
                if [[ $# -eq 0 ]]; then
                    print_error "--add-skill requires a skill name"
                    echo "Usage: ./install.sh --add-skill <skill-name>"
                    exit 1
                fi
                add_skill_name="$1"
                ;;
            --add-mcp)
                action="add-mcp"
                shift
                if [[ $# -eq 0 ]]; then
                    print_error "--add-mcp requires an MCP server name"
                    echo "Usage: ./install.sh --add-mcp <mcp-name>"
                    exit 1
                fi
                add_mcp_name="$1"
                ;;
            --remove-skill)
                action="remove-skill"
                shift
                if [[ $# -eq 0 ]]; then
                    print_error "--remove-skill requires a skill name"
                    echo "Usage: ./install.sh --remove-skill <skill-name>"
                    exit 1
                fi
                remove_skill_name="$1"
                ;;
            --remove-mcp)
                action="remove-mcp"
                shift
                if [[ $# -eq 0 ]]; then
                    print_error "--remove-mcp requires an MCP server name"
                    echo "Usage: ./install.sh --remove-mcp <mcp-name>"
                    exit 1
                fi
                remove_mcp_name="$1"
                ;;
            --update|-u)
                action="update"
                ;;
            --remove|-r)
                action="remove"
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
        "add-skill")
            do_add_skill "$add_skill_name"
            ;;
        "add-mcp")
            do_add_mcp "$add_mcp_name"
            ;;
        "remove-skill")
            do_remove_skill "$remove_skill_name"
            ;;
        "remove-mcp")
            do_remove_mcp "$remove_mcp_name"
            ;;
        "update")
            do_update
            ;;
        "remove")
            do_remove
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

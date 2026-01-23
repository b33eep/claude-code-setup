#!/bin/bash

# Claude Code Setup Installer
# Modular installation with support for custom modules
# MacOS focused - uses Homebrew for dependencies

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
CUSTOM_DIR="$CLAUDE_DIR/custom"
INSTALLED_FILE="$CLAUDE_DIR/installed.json"
MCP_CONFIG_FILE="$HOME/.claude.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================
# HELPER FUNCTIONS
# ============================================

print_header() {
    echo ""
    echo -e "${BLUE}$1${NC}"
    echo "$(echo "$1" | sed 's/./-/g')"
}

print_success() {
    echo -e "  ${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "  ${BLUE}-${NC} $1"
}

print_warning() {
    echo -e "  ${YELLOW}!${NC} $1"
}

print_error() {
    echo -e "  ${RED}✗${NC} $1"
}

# Initialize installed.json if it doesn't exist
init_installed_json() {
    if [ ! -f "$INSTALLED_FILE" ]; then
        echo '{"standards":[],"mcp":[],"skills":[]}' > "$INSTALLED_FILE"
    fi
}

# Check if a module is installed
is_installed() {
    local category=$1
    local module=$2
    jq -e ".${category} | index(\"${module}\")" "$INSTALLED_FILE" > /dev/null 2>&1
}

# Add module to installed list
add_to_installed() {
    local category=$1
    local module=$2
    if ! is_installed "$category" "$module"; then
        jq ".${category} += [\"${module}\"]" "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp" && mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"
    fi
}

# Get installed modules
get_installed() {
    local category=$1
    jq -r ".${category}[]" "$INSTALLED_FILE" 2>/dev/null || echo ""
}

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
    echo "  --list      Show installed and available modules"
    echo "  --help      Show this help message"
    echo ""
    echo "Custom Modules:"
    echo "  Place custom modules in ~/.claude/custom/"
    echo "  Structure: custom/{standards,mcp,skills}/"
    echo ""
}

# ============================================
# LIST MODULES
# ============================================

list_modules() {
    print_header "Installed Modules"

    echo ""
    echo "Standards:"
    local installed_standards=$(get_installed "standards")
    if [ -z "$installed_standards" ]; then
        print_info "(none)"
    else
        for s in $installed_standards; do
            print_success "$s"
        done
    fi

    echo ""
    echo "MCP Servers:"
    local installed_mcp=$(get_installed "mcp")
    if [ -z "$installed_mcp" ]; then
        print_info "(none)"
    else
        for m in $installed_mcp; do
            print_success "$m"
        done
    fi

    echo ""
    echo "Skills:"
    local installed_skills=$(get_installed "skills")
    if [ -z "$installed_skills" ]; then
        print_info "(none)"
    else
        for s in $installed_skills; do
            print_success "$s"
        done
    fi

    print_header "Available Modules"

    echo ""
    echo "Standards:"
    for f in "$SCRIPT_DIR/templates/modules/standards/"*.md; do
        [ -f "$f" ] || continue
        local name=$(basename "$f" .md)
        if is_installed "standards" "$name"; then
            print_info "$name (installed)"
        else
            echo "  [ ] $name"
        fi
    done

    echo ""
    echo "MCP Servers:"
    for f in "$SCRIPT_DIR/mcp/"*.json; do
        [ -f "$f" ] || continue
        local name=$(basename "$f" .json)
        local desc=$(jq -r '.description' "$f")
        if is_installed "mcp" "$name"; then
            print_info "$name (installed)"
        else
            echo "  [ ] $name - $desc"
        fi
    done

    echo ""
    echo "Skills:"
    for d in "$SCRIPT_DIR/skills/"*/; do
        [ -d "$d" ] || continue
        local name=$(basename "$d")
        if is_installed "skills" "$name"; then
            print_info "$name (installed)"
        else
            echo "  [ ] $name"
        fi
    done

    # Check for custom modules
    if [ -d "$CUSTOM_DIR" ]; then
        print_header "Custom Modules"

        if [ -d "$CUSTOM_DIR/standards" ] && [ "$(ls -A "$CUSTOM_DIR/standards" 2>/dev/null)" ]; then
            echo ""
            echo "Custom Standards:"
            for f in "$CUSTOM_DIR/standards/"*.md; do
                [ -f "$f" ] || continue
                local name=$(basename "$f" .md)
                if is_installed "standards" "custom:$name"; then
                    print_success "$name (installed)"
                else
                    echo "  [ ] $name"
                fi
            done
        fi

        if [ -d "$CUSTOM_DIR/mcp" ] && [ "$(ls -A "$CUSTOM_DIR/mcp" 2>/dev/null)" ]; then
            echo ""
            echo "Custom MCP Servers:"
            for f in "$CUSTOM_DIR/mcp/"*.json; do
                [ -f "$f" ] || continue
                local name=$(basename "$f" .json)
                if is_installed "mcp" "custom:$name"; then
                    print_success "$name (installed)"
                else
                    echo "  [ ] $name"
                fi
            done
        fi

        if [ -d "$CUSTOM_DIR/skills" ] && [ "$(ls -A "$CUSTOM_DIR/skills" 2>/dev/null)" ]; then
            echo ""
            echo "Custom Skills:"
            for d in "$CUSTOM_DIR/skills/"*/; do
                [ -d "$d" ] || continue
                local name=$(basename "$d")
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

# ============================================
# SELECT MODULES (Interactive)
# ============================================

select_standards() {
    local mode=$1  # "install" or "add"
    SELECTED_STANDARDS=()

    echo ""
    echo "Coding Standards (enter numbers separated by space, or 'none'):"
    echo ""

    local i=1
    local standards=()

    for f in "$SCRIPT_DIR/templates/modules/standards/"*.md; do
        [ -f "$f" ] || continue
        local name=$(basename "$f" .md)
        if [ "$mode" = "add" ] && is_installed "standards" "$name"; then
            continue
        fi
        standards+=("$name")
        echo "  $i) $name"
        ((i++))
    done

    # Custom standards
    if [ -d "$CUSTOM_DIR/standards" ]; then
        for f in "$CUSTOM_DIR/standards/"*.md; do
            [ -f "$f" ] || continue
            local name=$(basename "$f" .md)
            if [ "$mode" = "add" ] && is_installed "standards" "custom:$name"; then
                continue
            fi
            standards+=("custom:$name")
            echo "  $i) $name (custom)"
            ((i++))
        done
    fi

    if [ ${#standards[@]} -eq 0 ]; then
        echo "  (all standards already installed)"
        return
    fi

    echo ""
    read -p "Select (e.g., '1 2' or 'none'): " selection

    if [ "$selection" != "none" ] && [ -n "$selection" ]; then
        for num in $selection; do
            if [ "$num" -ge 1 ] && [ "$num" -le ${#standards[@]} ] 2>/dev/null; then
                SELECTED_STANDARDS+=("${standards[$((num-1))]}")
            fi
        done
    fi
}

select_mcp() {
    local mode=$1
    SELECTED_MCP=()

    echo ""
    echo "MCP Servers (enter numbers separated by space, or 'none'):"
    echo ""

    local i=1
    local mcps=()

    for f in "$SCRIPT_DIR/mcp/"*.json; do
        [ -f "$f" ] || continue
        local name=$(basename "$f" .json)
        local desc=$(jq -r '.description' "$f")
        if [ "$mode" = "add" ] && is_installed "mcp" "$name"; then
            continue
        fi
        mcps+=("$name")
        echo "  $i) $name - $desc"
        ((i++))
    done

    # Custom MCP
    if [ -d "$CUSTOM_DIR/mcp" ]; then
        for f in "$CUSTOM_DIR/mcp/"*.json; do
            [ -f "$f" ] || continue
            local name=$(basename "$f" .json)
            local desc=$(jq -r '.description' "$f" 2>/dev/null || echo "Custom MCP server")
            if [ "$mode" = "add" ] && is_installed "mcp" "custom:$name"; then
                continue
            fi
            mcps+=("custom:$name")
            echo "  $i) $name (custom) - $desc"
            ((i++))
        done
    fi

    if [ ${#mcps[@]} -eq 0 ]; then
        echo "  (all MCP servers already installed)"
        return
    fi

    echo ""
    read -p "Select (e.g., '1 2' or 'none'): " selection

    if [ "$selection" != "none" ] && [ -n "$selection" ]; then
        for num in $selection; do
            if [ "$num" -ge 1 ] && [ "$num" -le ${#mcps[@]} ] 2>/dev/null; then
                SELECTED_MCP+=("${mcps[$((num-1))]}")
            fi
        done
    fi
}

select_skills() {
    local mode=$1
    SELECTED_SKILLS=()

    echo ""
    echo "Skills (enter numbers separated by space, or 'none'):"
    echo ""

    local i=1
    local skills=()

    for d in "$SCRIPT_DIR/skills/"*/; do
        [ -d "$d" ] || continue
        local name=$(basename "$d")
        if [ "$mode" = "add" ] && is_installed "skills" "$name"; then
            continue
        fi
        skills+=("$name")
        echo "  $i) $name"
        ((i++))
    done

    # Custom skills
    if [ -d "$CUSTOM_DIR/skills" ]; then
        for d in "$CUSTOM_DIR/skills/"*/; do
            [ -d "$d" ] || continue
            local name=$(basename "$d")
            if [ "$mode" = "add" ] && is_installed "skills" "custom:$name"; then
                continue
            fi
            skills+=("custom:$name")
            echo "  $i) $name (custom)"
            ((i++))
        done
    fi

    if [ ${#skills[@]} -eq 0 ]; then
        echo "  (all skills already installed)"
        return
    fi

    echo ""
    read -p "Select (e.g., '1' or 'none'): " selection

    if [ "$selection" != "none" ] && [ -n "$selection" ]; then
        for num in $selection; do
            if [ "$num" -ge 1 ] && [ "$num" -le ${#skills[@]} ] 2>/dev/null; then
                SELECTED_SKILLS+=("${skills[$((num-1))]}")
            fi
        done
    fi
}

# ============================================
# BUILD CLAUDE.MD
# ============================================

build_claude_md() {
    local standards_to_include=("$@")

    # Start with base template
    local content=$(cat "$SCRIPT_DIR/templates/base/global-CLAUDE.md")

    # Build standards section
    local standards_content=""

    # Get all installed standards + new selections
    local all_standards=$(get_installed "standards")
    for s in "${standards_to_include[@]}"; do
        if [[ ! " $all_standards " =~ " $s " ]]; then
            all_standards="$all_standards $s"
        fi
    done

    for standard in $all_standards; do
        local file=""
        if [[ "$standard" == custom:* ]]; then
            local name="${standard#custom:}"
            file="$CUSTOM_DIR/standards/${name}.md"
        else
            file="$SCRIPT_DIR/templates/modules/standards/${standard}.md"
        fi

        if [ -f "$file" ]; then
            standards_content+="\n---\n\n$(cat "$file")\n"
        fi
    done

    # Replace placeholder with standards content
    if [ -n "$standards_content" ]; then
        content="${content//\{\{STANDARDS_MODULES\}\}/$standards_content}"
    else
        content="${content//\{\{STANDARDS_MODULES\}\}/}"
    fi

    echo -e "$content" > "$CLAUDE_DIR/CLAUDE.md"
}

# ============================================
# INSTALL MCP SERVER
# ============================================

install_mcp() {
    local mcp_name=$1
    local config_file=""

    if [[ "$mcp_name" == custom:* ]]; then
        local name="${mcp_name#custom:}"
        config_file="$CUSTOM_DIR/mcp/${name}.json"
    else
        config_file="$SCRIPT_DIR/mcp/${mcp_name}.json"
    fi

    if [ ! -f "$config_file" ]; then
        print_error "MCP config not found: $config_file"
        return 1
    fi

    local name=$(jq -r '.name' "$config_file")
    local requires_key=$(jq -r '.requiresApiKey' "$config_file")
    local config=$(jq -r '.config' "$config_file")

    # Initialize .claude.json if needed
    if [ ! -f "$MCP_CONFIG_FILE" ]; then
        echo '{"mcpServers":{}}' > "$MCP_CONFIG_FILE"
    fi

    # Handle API keys if required
    if [ "$requires_key" = "true" ]; then
        # Show instructions
        local instructions=$(jq -r '.apiKeyInstructions[]' "$config_file" 2>/dev/null)
        if [ -n "$instructions" ]; then
            echo ""
            echo "  Setup instructions:"
            jq -r '.apiKeyInstructions[]' "$config_file" | while read -r line; do
                echo "    $line"
            done
            echo ""
        fi

        # Check if single key or multiple
        local api_keys=$(jq -r '.apiKeys' "$config_file" 2>/dev/null)

        if [ "$api_keys" != "null" ]; then
            # Multiple API keys
            local key_count=$(jq -r '.apiKeys | length' "$config_file")
            for ((i=0; i<key_count; i++)); do
                local key_name=$(jq -r ".apiKeys[$i].name" "$config_file")
                local key_prompt=$(jq -r ".apiKeys[$i].prompt" "$config_file")
                read -p "  $key_prompt: " key_value
                if [ -z "$key_value" ]; then
                    print_warning "Skipping $name (no API key provided)"
                    return 1
                fi
                config=$(echo "$config" | sed "s/{{${key_name}}}/${key_value}/g")
            done
        else
            # Single API key
            local key_name=$(jq -r '.apiKeyName' "$config_file")
            local key_prompt=$(jq -r '.apiKeyPrompt' "$config_file")
            read -p "  $key_prompt: " key_value
            if [ -z "$key_value" ]; then
                print_warning "Skipping $name (no API key provided)"
                return 1
            fi
            config=$(echo "$config" | sed "s/{{${key_name}}}/${key_value}/g")
        fi
    fi

    # Add to .claude.json
    jq --argjson config "$config" ".mcpServers[\"$name\"] = \$config" "$MCP_CONFIG_FILE" > "$MCP_CONFIG_FILE.tmp" && mv "$MCP_CONFIG_FILE.tmp" "$MCP_CONFIG_FILE"

    return 0
}

# ============================================
# INSTALL SKILL
# ============================================

install_skill() {
    local skill_name=$1
    local source_dir=""

    if [[ "$skill_name" == custom:* ]]; then
        local name="${skill_name#custom:}"
        source_dir="$CUSTOM_DIR/skills/$name"
    else
        source_dir="$SCRIPT_DIR/skills/$skill_name"
    fi

    if [ ! -d "$source_dir" ]; then
        print_error "Skill not found: $source_dir"
        return 1
    fi

    local target_dir="$CLAUDE_DIR/skills/$(basename "$source_dir")"
    mkdir -p "$CLAUDE_DIR/skills"
    cp -r "$source_dir" "$target_dir"

    return 0
}

# ============================================
# MAIN INSTALLATION
# ============================================

do_install() {
    local mode=$1  # "install" or "add"

    if [ "$mode" = "install" ]; then
        echo ""
        echo "Claude Code Setup Installer"
        echo "============================"
    else
        echo ""
        echo "Claude Code Setup - Add Modules"
        echo "================================"
    fi

    # Check dependencies
    print_header "Dependencies"

    if ! command -v brew &> /dev/null; then
        print_error "Homebrew not found. Please install from https://brew.sh"
        exit 1
    fi
    print_info "brew (found)"

    if ! command -v jq &> /dev/null; then
        echo "  + jq (installing via brew...)"
        brew install jq --quiet
    else
        print_info "jq (found)"
    fi

    # Create directories
    mkdir -p "$CLAUDE_DIR"
    mkdir -p "$CLAUDE_DIR/commands"
    mkdir -p "$CLAUDE_DIR/skills"
    mkdir -p "$CUSTOM_DIR/standards"
    mkdir -p "$CUSTOM_DIR/mcp"
    mkdir -p "$CUSTOM_DIR/skills"

    init_installed_json

    # Select modules
    print_header "Select Modules"

    select_standards "$mode"
    select_mcp "$mode"
    select_skills "$mode"

    # Install commands (always)
    print_header "Installing Commands"

    for cmd in "$SCRIPT_DIR/commands/"*.md; do
        [ -f "$cmd" ] || continue
        local filename=$(basename "$cmd")
        cp "$cmd" "$CLAUDE_DIR/commands/"
        print_success "$filename"
    done

    # Build CLAUDE.md
    print_header "Building CLAUDE.md"

    build_claude_md "${SELECTED_STANDARDS[@]}"

    # Track installed standards
    for s in "${SELECTED_STANDARDS[@]}"; do
        add_to_installed "standards" "$s"
    done

    local installed_count=$(get_installed "standards" | wc -w | tr -d ' ')
    print_success "CLAUDE.md built with $installed_count standard module(s)"

    # Install MCP servers
    if [ ${#SELECTED_MCP[@]} -gt 0 ]; then
        print_header "Installing MCP Servers"

        for mcp in "${SELECTED_MCP[@]}"; do
            local display_name="${mcp#custom:}"
            echo ""
            echo "  Installing $display_name..."
            if install_mcp "$mcp"; then
                add_to_installed "mcp" "$mcp"
                print_success "$display_name configured"
            fi
        done
    fi

    # Install skills
    if [ ${#SELECTED_SKILLS[@]} -gt 0 ]; then
        print_header "Installing Skills"

        for skill in "${SELECTED_SKILLS[@]}"; do
            local display_name="${skill#custom:}"
            if install_skill "$skill"; then
                add_to_installed "skills" "$skill"
                print_success "$display_name installed"
            fi
        done
    fi

    # Done
    print_header "Installation Complete"

    echo ""
    echo "Installed to:"
    echo "  ~/.claude/CLAUDE.md"
    echo "  ~/.claude/commands/"
    echo "  ~/.claude/skills/"
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
# UPDATE INSTALLATION
# ============================================

do_update() {
    echo ""
    echo "Claude Code Setup - Update"
    echo "=========================="

    init_installed_json

    # Update commands
    print_header "Updating Commands"

    for cmd in "$SCRIPT_DIR/commands/"*.md; do
        [ -f "$cmd" ] || continue
        local filename=$(basename "$cmd")
        cp "$cmd" "$CLAUDE_DIR/commands/"
        print_success "$filename"
    done

    # Rebuild CLAUDE.md with current installed standards
    print_header "Rebuilding CLAUDE.md"

    local installed_standards=$(get_installed "standards")
    build_claude_md $installed_standards
    print_success "CLAUDE.md rebuilt"

    # Update skills
    print_header "Updating Skills"

    local installed_skills=$(get_installed "skills")
    for skill in $installed_skills; do
        local source_dir=""
        local display_name=""

        if [[ "$skill" == custom:* ]]; then
            local name="${skill#custom:}"
            source_dir="$CUSTOM_DIR/skills/$name"
            display_name="$name (custom)"
        else
            source_dir="$SCRIPT_DIR/skills/$skill"
            display_name="$skill"
        fi

        if [ -d "$source_dir" ]; then
            local target_dir="$CLAUDE_DIR/skills/$(basename "$source_dir")"
            rm -rf "$target_dir"
            cp -r "$source_dir" "$target_dir"
            print_success "$display_name"
        else
            print_warning "$display_name (source not found, skipped)"
        fi
    done

    echo ""
    print_success "Update complete!"
    echo ""
}

# ============================================
# MAIN
# ============================================

case "${1:-}" in
    --help|-h)
        show_usage
        ;;
    --list|-l)
        init_installed_json
        list_modules
        ;;
    --add|-a)
        do_install "add"
        ;;
    --update|-u)
        do_update
        ;;
    "")
        if [ -f "$INSTALLED_FILE" ]; then
            echo ""
            echo "Existing installation detected."
            echo "Use --add to add modules or --update to update."
            echo ""
            read -p "Continue with fresh install? (y/N): " confirm
            if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
                echo "Cancelled."
                exit 0
            fi
            # Reset installed.json for fresh install
            echo '{"standards":[],"mcp":[],"skills":[]}' > "$INSTALLED_FILE"
        fi
        do_install "install"
        ;;
    *)
        echo "Unknown option: $1"
        show_usage
        exit 1
        ;;
esac

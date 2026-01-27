#!/bin/bash

# Permission rules for Claude Code settings.json

# Allow rules needed by /claude-code-setup command
readonly UPGRADE_ALLOW_RULES=(
    "Bash(mktemp -d:*)"
    "Bash(git clone --depth 1:*)"
    "Bash(curl -fsSL:*)"
    "Bash(jq:*)"
    "Bash(ls -1:*)"
    "Bash(rm -rf /tmp/claude-setup-:*)"
)

# Configure permission allow rules in settings.json
# Merges rules into existing permissions without overwriting user rules
configure_permissions() {
    local claude_settings="$CLAUDE_DIR/settings.json"

    # Ensure settings.json exists and is valid
    if [[ -f "$claude_settings" ]]; then
        if ! jq -e '.' "$claude_settings" > /dev/null 2>&1; then
            print_warning "settings.json appears corrupted, recreating..."
            echo '{}' > "$claude_settings"
        fi
    else
        echo '{}' > "$claude_settings"
    fi

    # Ensure permissions.allow array exists
    local settings
    settings=$(jq '.permissions //= {} | .permissions.allow //= []' "$claude_settings")

    # Add missing rules
    local rule
    local added=0
    for rule in "${UPGRADE_ALLOW_RULES[@]}"; do
        if ! jq -e --arg r "$rule" '.permissions.allow | index($r)' <<< "$settings" > /dev/null 2>&1; then
            settings=$(jq --arg r "$rule" '.permissions.allow += [$r]' <<< "$settings")
            added=$((added + 1))
        fi
    done

    if [[ "$added" -eq 0 ]]; then
        print_info "Permission rules already configured"
        return 0
    fi

    # Write back atomically
    if ! jq '.' <<< "$settings" > "$claude_settings.tmp" 2>/dev/null; then
        print_error "Failed to update permissions in settings.json"
        rm -f "$claude_settings.tmp"
        return 1
    fi
    mv "$claude_settings.tmp" "$claude_settings"

    print_success "Permission rules added ($added rules for /claude-code-setup)"
}

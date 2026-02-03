#!/bin/bash

# Hooks configuration for Claude Code Setup

# Configure update notification hook
configure_hooks() {
    local claude_settings="$CLAUDE_DIR/settings.json"
    local hook_script="$CLAUDE_DIR/hooks/check-update.sh"

    # Check if hook already configured
    if [[ -f "$claude_settings" ]] && jq -e '.hooks.SessionStart' "$claude_settings" > /dev/null 2>&1; then
        print_info "Hooks already configured"
        return 0
    fi

    # Copy hook script
    mkdir -p "$CLAUDE_DIR/hooks"
    cp "$SCRIPT_DIR/hooks/check-update.sh" "$hook_script"
    chmod +x "$hook_script"

    # Ensure settings.json exists
    if [[ -f "$claude_settings" ]]; then
        if ! jq -e '.' "$claude_settings" > /dev/null 2>&1; then
            print_warning "settings.json appears corrupted, recreating..."
            echo '{}' > "$claude_settings"
        fi
    else
        echo '{}' > "$claude_settings"
    fi

    # Add SessionStart hook configuration
    # Matcher: startup (new session) or clear (after /clear)
    local hook_config
    hook_config=$(cat <<EOF
[{
    "matcher": "startup|clear",
    "hooks": [{
        "type": "command",
        "command": "$hook_script"
    }]
}]
EOF
)

    if ! jq --argjson hooks "$hook_config" '.hooks.SessionStart = $hooks' "$claude_settings" > "$claude_settings.tmp" 2>/dev/null; then
        print_error "Failed to configure hooks in settings.json"
        rm -f "$claude_settings.tmp"
        return 1
    fi
    mv "$claude_settings.tmp" "$claude_settings"

    print_success "Update notification hook enabled"
}

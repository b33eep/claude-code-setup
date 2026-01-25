#!/bin/bash

# ccstatusline configuration

# Configure status line
configure_statusline() {
    local claude_settings="$CLAUDE_DIR/settings.json"
    local ccstatus_settings="$CCSTATUS_CONFIG_DIR/settings.json"

    # Check if already configured
    if [[ -f "$claude_settings" ]] && jq -e '.statusLine' "$claude_settings" > /dev/null 2>&1; then
        print_info "statusLine already configured"
        return 0
    fi

    # Check if npx/Node.js is available (required for ccstatusline)
    if ! command -v npx &>/dev/null; then
        echo ""
        print_warning "ccstatusline requires Node.js (npx not found)"
        print_info "Install Node.js first, then re-run: ./install.sh --add"
        print_info "Skipping status line configuration"
        return 0
    fi

    # Non-interactive mode: auto-enable statusline
    if [[ "$YES_MODE" = "true" ]]; then
        print_info "Enabling status line (non-interactive mode)"
    else
        echo ""
        echo "ccstatusline shows context usage in the status bar (e.g., Ctx: 21.9%)"
        echo "Useful to know when to run /clear-session"
        echo ""
        read -rp "Enable context status line? (Y/n): " enable_statusline

        if [[ "$enable_statusline" = "n" ]] || [[ "$enable_statusline" = "N" ]]; then
            print_info "Status line skipped"
            return 0
        fi
    fi

    # 1. Configure Claude settings
    # Validate existing settings.json if present
    if [[ -f "$claude_settings" ]]; then
        if ! jq -e '.' "$claude_settings" > /dev/null 2>&1; then
            print_warning "settings.json appears corrupted, recreating..."
            echo '{}' > "$claude_settings"
        fi
    else
        echo '{}' > "$claude_settings"
    fi

    # Update settings.json with error handling
    if ! jq '.statusLine = "npx -y ccstatusline@latest"' "$claude_settings" > "$claude_settings.tmp" 2>/dev/null; then
        print_error "Failed to update settings.json"
        rm -f "$claude_settings.tmp"
        return 1
    fi
    mv "$claude_settings.tmp" "$claude_settings"

    # 2. Create default ccstatusline config if not exists
    mkdir -p "$CCSTATUS_CONFIG_DIR"
    if [[ ! -f "$ccstatus_settings" ]]; then
        cat > "$ccstatus_settings" << 'CCEOF'
{
  "version": 3,
  "lines": [
    [
      {"id": "1", "type": "model"},
      {"id": "2", "type": "separator"},
      {"id": "3", "type": "tokens-total"},
      {"id": "4", "type": "separator"},
      {"id": "5", "type": "context-length", "color": "brightBlack"},
      {"id": "6", "type": "separator"},
      {"id": "7", "type": "context-percentage"},
      {"id": "8", "type": "separator"},
      {"id": "9", "type": "git-branch", "color": "magenta"},
      {"id": "10", "type": "separator"},
      {"id": "11", "type": "git-changes", "color": "yellow"}
    ],
    [],
    []
  ],
  "flexMode": "full-minus-40",
  "compactThreshold": 60,
  "colorLevel": 2
}
CCEOF
        print_success "Status line enabled with default config"
        echo "  Customize: npx ccstatusline@latest"
    else
        print_success "Status line enabled (using existing config)"
    fi
}

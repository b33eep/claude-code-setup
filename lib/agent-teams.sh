#!/bin/bash

# Agent Teams configuration for Claude Code Setup

# Configure Agent Teams (experimental)
configure_agent_teams() {
    local claude_settings="$CLAUDE_DIR/settings.json"

    # Check if already configured
    if [[ -f "$claude_settings" ]] && jq -e '.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS' "$claude_settings" > /dev/null 2>&1; then
        print_info "Agent Teams already configured"
        return 0
    fi

    # Non-interactive mode: skip (experimental, don't auto-enable)
    if [[ "$YES_MODE" = "true" ]]; then
        print_info "Agent Teams: skipped (enable manually or re-run without --yes)"
        return 0
    fi

    echo ""
    echo "Agent Teams lets multiple Claude instances work together."
    echo "Required for /with-advisor and /delegate commands."
    echo ""
    local enable_agent_teams
    enable_agent_teams=$(read_input "Enable Agent Teams (experimental)? (y/N): ") || enable_agent_teams="N"

    if [[ "$enable_agent_teams" != "y" ]] && [[ "$enable_agent_teams" != "Y" ]]; then
        print_info "Agent Teams skipped"
        return 0
    fi

    # Ensure settings.json exists and is valid
    if [[ -f "$claude_settings" ]]; then
        if ! jq -e '.' "$claude_settings" > /dev/null 2>&1; then
            print_warning "settings.json appears corrupted, recreating..."
            echo '{}' > "$claude_settings"
        fi
    else
        echo '{}' > "$claude_settings"
    fi

    # Add env var to settings.json
    if ! jq '.env = (.env // {}) | .env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"' "$claude_settings" > "$claude_settings.tmp" 2>/dev/null; then
        print_error "Failed to configure Agent Teams in settings.json"
        rm -f "$claude_settings.tmp"
        return 1
    fi
    mv "$claude_settings.tmp" "$claude_settings"

    print_success "Agent Teams enabled"
}
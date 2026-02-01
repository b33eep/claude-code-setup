#!/bin/bash

# External plugins management via Claude CLI

# Global array for selected external plugins
SELECTED_EXTERNAL_PLUGINS=()

# Check if claude CLI is available
has_claude_cli() {
    command -v claude &>/dev/null
}

# Check if a marketplace is already registered
marketplace_exists() {
    local marketplace_name=$1
    claude plugin marketplace list 2>/dev/null | grep -q "❯ $marketplace_name"
}

# Add a marketplace from GitHub repo
add_marketplace() {
    local repo=$1
    local name=$2

    if marketplace_exists "$name"; then
        print_info "Marketplace $name already registered"
        return 0
    fi

    echo "  Adding marketplace $name..."
    if claude plugin marketplace add "$repo" &>/dev/null; then
        print_success "Marketplace $name added"
        return 0
    else
        print_error "Failed to add marketplace $name"
        return 1
    fi
}

# Check if a plugin is already installed
plugin_installed() {
    local plugin_id=$1
    local marketplace=$2
    claude plugin list 2>/dev/null | grep -q "$plugin_id@$marketplace"
}

# Install a single external plugin
install_external_plugin() {
    local plugin_id=$1
    local marketplace=$2
    local repo=$3

    # Ensure marketplace is registered
    if ! marketplace_exists "$marketplace"; then
        if ! add_marketplace "$repo" "$marketplace"; then
            return 1
        fi
    fi

    # Check if already installed
    if plugin_installed "$plugin_id" "$marketplace"; then
        print_info "$plugin_id already installed"
        return 0
    fi

    # Install the plugin
    echo "  Installing $plugin_id..."
    if claude plugin install "$plugin_id@$marketplace" &>/dev/null; then
        print_success "$plugin_id installed"
        return 0
    else
        print_error "Failed to install $plugin_id"
        return 1
    fi
}

# Load external plugins config (base + custom merged)
# Sets global: EXTERNAL_PLUGINS_JSON
load_external_plugins_config() {
    local base_config="$SCRIPT_DIR/external-plugins.json"
    local custom_config="$CUSTOM_DIR/external-plugins.json"

    if [[ ! -f "$base_config" ]]; then
        EXTERNAL_PLUGINS_JSON="{}"
        return
    fi

    EXTERNAL_PLUGINS_JSON=$(cat "$base_config")

    # Merge custom config if exists
    if [[ -f "$custom_config" ]]; then
        # Merge marketplaces
        local custom_marketplaces
        custom_marketplaces=$(jq -r '.marketplaces // {}' "$custom_config")
        EXTERNAL_PLUGINS_JSON=$(echo "$EXTERNAL_PLUGINS_JSON" | jq --argjson custom "$custom_marketplaces" '.marketplaces += $custom')

        # Merge plugins
        local custom_plugins
        custom_plugins=$(jq -r '.plugins // []' "$custom_config")
        EXTERNAL_PLUGINS_JSON=$(echo "$EXTERNAL_PLUGINS_JSON" | jq --argjson custom "$custom_plugins" '.plugins += $custom')
    fi
}

# Get list of available external plugins
# Returns space-separated plugin IDs
get_available_external_plugins() {
    echo "$EXTERNAL_PLUGINS_JSON" | jq -r '.plugins[].id' | tr '\n' ' ' | sed 's/ $//'
}

# Get plugin description
get_plugin_description() {
    local plugin_id=$1
    echo "$EXTERNAL_PLUGINS_JSON" | jq -r --arg id "$plugin_id" '.plugins[] | select(.id == $id) | .description // ""'
}

# Get plugin marketplace
get_plugin_marketplace() {
    local plugin_id=$1
    echo "$EXTERNAL_PLUGINS_JSON" | jq -r --arg id "$plugin_id" '.plugins[] | select(.id == $id) | .marketplace'
}

# Get marketplace repo
get_marketplace_repo() {
    local marketplace=$1
    echo "$EXTERNAL_PLUGINS_JSON" | jq -r --arg m "$marketplace" '.marketplaces[$m].repo // ""'
}

# Get default selected plugins
get_default_external_plugins() {
    echo "$EXTERNAL_PLUGINS_JSON" | jq -r '.plugins[] | select(.default == true) | .id' | tr '\n' ' ' | sed 's/ $//'
}

# Select external plugins interactively
select_external_plugins() {
    # mode parameter reserved for future use (install vs add)
    SELECTED_EXTERNAL_PLUGINS=()

    # Skip in test mode
    if [[ "${SKIP_EXTERNAL_PLUGINS:-}" = "1" ]]; then
        return
    fi

    # Skip if claude CLI not available
    if ! has_claude_cli; then
        print_info "External plugins: skipped (claude CLI not found)"
        return
    fi

    # Skip in non-interactive mode
    if [[ "$YES_MODE" = "true" ]]; then
        print_info "External plugins: skipped (non-interactive mode)"
        return
    fi

    # Load config
    load_external_plugins_config

    # Get available plugins
    local plugins_str
    plugins_str=$(get_available_external_plugins)

    if [[ -z "$plugins_str" ]]; then
        return
    fi

    # Build descriptions (pipe-separated)
    local descs_str=""
    local plugin_id desc marketplace
    for plugin_id in $plugins_str; do
        desc=$(get_plugin_description "$plugin_id")
        marketplace=$(get_plugin_marketplace "$plugin_id")

        # Check if already installed
        if plugin_installed "$plugin_id" "$marketplace"; then
            desc="$desc [installed]"
        fi

        if [[ -n "$descs_str" ]]; then
            descs_str="$descs_str|$desc"
        else
            descs_str="$desc"
        fi
    done

    # Filter out already installed plugins from selection
    local available_str=""
    local available_descs=""
    local i=0
    local desc_arr
    IFS='|' read -ra desc_arr <<< "$descs_str"

    for plugin_id in $plugins_str; do
        marketplace=$(get_plugin_marketplace "$plugin_id")
        if ! plugin_installed "$plugin_id" "$marketplace"; then
            available_str="$available_str $plugin_id"
            if [[ -n "$available_descs" ]]; then
                available_descs="$available_descs|${desc_arr[$i]}"
            else
                available_descs="${desc_arr[$i]}"
            fi
        fi
        ((i++)) || true
    done
    available_str="${available_str# }"

    if [[ -z "$available_str" ]]; then
        echo ""
        echo "  (all external plugins already installed)"
        return
    fi

    # Get defaults (none by default, plugins opt-in)
    local defaults_str=""
    defaults_str=$(get_default_external_plugins)

    # Show header
    echo ""
    echo "External Plugins (via Claude CLI):"
    echo ""

    # Show already installed
    for plugin_id in $plugins_str; do
        marketplace=$(get_plugin_marketplace "$plugin_id")
        if plugin_installed "$plugin_id" "$marketplace"; then
            desc=$(get_plugin_description "$plugin_id")
            echo "     $plugin_id - $desc [installed]"
        fi
    done

    # Interactive toggle selection
    interactive_select "$available_str" "$available_descs" "$defaults_str" "" "false" "SELECTED_EXTERNAL_PLUGINS"
}

# Install selected external plugins
install_external_plugins() {
    if [[ ${#SELECTED_EXTERNAL_PLUGINS[@]} -eq 0 ]]; then
        return
    fi

    print_header "Installing External Plugins"

    local plugin_id marketplace repo
    for plugin_id in "${SELECTED_EXTERNAL_PLUGINS[@]}"; do
        marketplace=$(get_plugin_marketplace "$plugin_id")
        repo=$(get_marketplace_repo "$marketplace")

        echo ""
        install_external_plugin "$plugin_id" "$marketplace" "$repo"

        # Track in installed.json
        add_to_installed "external_plugins" "$plugin_id@$marketplace"
    done
}

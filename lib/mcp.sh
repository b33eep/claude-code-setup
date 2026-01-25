#!/bin/bash

# MCP server installation

# Install a single MCP server
install_mcp() {
    local mcp_name=$1
    local config_file=""
    local name
    local requires_key
    local config

    if [[ "$mcp_name" == custom:* ]]; then
        name="${mcp_name#custom:}"
        config_file="$CUSTOM_DIR/mcp/${name}.json"
    else
        config_file="$SCRIPT_DIR/mcp/${mcp_name}.json"
    fi

    if [[ ! -f "$config_file" ]]; then
        print_error "MCP config not found: $config_file"
        return 1
    fi

    name=$(jq -r '.name' "$config_file")
    requires_key=$(jq -r '.requiresApiKey' "$config_file")
    config=$(jq -r '.config' "$config_file")

    # Initialize .claude.json if needed
    if [[ ! -f "$MCP_CONFIG_FILE" ]]; then
        echo '{"mcpServers":{}}' > "$MCP_CONFIG_FILE"
    fi

    # Handle API keys if required
    local instructions
    local api_keys
    local key_count
    local key_name
    local key_prompt
    local key_value

    if [[ "$requires_key" = "true" ]]; then
        # Show instructions
        instructions=$(jq -r '.apiKeyInstructions[]' "$config_file" 2>/dev/null)
        if [[ -n "$instructions" ]]; then
            echo ""
            echo "  Setup instructions:"
            jq -r '.apiKeyInstructions[]' "$config_file" | while read -r line; do
                echo "    $line"
            done
            echo ""
        fi

        # Check if single key or multiple
        api_keys=$(jq -r '.apiKeys' "$config_file" 2>/dev/null)

        if [[ "$api_keys" != "null" ]]; then
            # Multiple API keys
            key_count=$(jq -r '.apiKeys | length' "$config_file")
            for ((i=0; i<key_count; i++)); do
                key_name=$(jq -r ".apiKeys[$i].name" "$config_file")
                key_prompt=$(jq -r ".apiKeys[$i].prompt" "$config_file")
                read -rp "  $key_prompt: " key_value
                if [[ -z "$key_value" ]]; then
                    print_warning "Skipping $name (no API key provided)"
                    return 1
                fi
                config=${config//\{\{${key_name}\}\}/${key_value}}
            done
        else
            # Single API key
            key_name=$(jq -r '.apiKeyName' "$config_file")
            key_prompt=$(jq -r '.apiKeyPrompt' "$config_file")
            read -rp "  $key_prompt: " key_value
            if [[ -z "$key_value" ]]; then
                print_warning "Skipping $name (no API key provided)"
                return 1
            fi
            config=${config//\{\{${key_name}\}\}/${key_value}}
        fi
    fi

    # Add to .claude.json
    jq --argjson config "$config" ".mcpServers[\"$name\"] = \$config" "$MCP_CONFIG_FILE" > "$MCP_CONFIG_FILE.tmp" && mv "$MCP_CONFIG_FILE.tmp" "$MCP_CONFIG_FILE"

    return 0
}

#!/bin/bash
set -euo pipefail

# Discovery script for /claude-code-setup command
# Outputs JSON to stdout with installation status
# All diagnostics go to stderr
#
# NOT sourced by install.sh — standalone executable invoked by the command markdown

# ============================================
# VARIABLE INITIALIZATION
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
CUSTOM_DIR="$CLAUDE_DIR/custom"
INSTALLED_FILE="$CLAUDE_DIR/installed.json"
# shellcheck disable=SC2034  # Used by sourced helpers.sh (get_content_version)
CONTENT_VERSION_FILE="$SCRIPT_DIR/templates/VERSION"
# Env override needed for tests (Record 040 spec uses $HOME/.claude.json)
MCP_CONFIG_FILE="${MCP_CONFIG_FILE:-$HOME/.claude.json}"

# ============================================
# SOURCE HELPERS (only helpers.sh)
# ============================================

# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"

# ============================================
# ERROR CASES
# ============================================

# jq must be available (user has a working install)
if ! command -v jq &>/dev/null; then
    echo "Error: jq not found. Please install jq first." >&2
    exit 1
fi

# No installed.json → not installed
if [[ ! -f "$INSTALLED_FILE" ]]; then
    echo '{"error":"not_installed"}'
    exit 0
fi

# ============================================
# GATHER DATA
# ============================================

# 1. Base versions (validate numeric to prevent set -e abort on malformed data)
installed_version=$(get_installed_content_version)
available_version=$(get_content_version)
[[ "$installed_version" =~ ^[0-9]+$ ]] || installed_version=0
[[ "$available_version" =~ ^[0-9]+$ ]] || available_version=0
if [[ "$installed_version" -lt "$available_version" ]]; then
    update_available=true
else
    update_available=false
fi

# 2. Installed modules from installed.json
installed_skills_json=$(jq -c '.skills // []' "$INSTALLED_FILE")
installed_mcp_json=$(jq -c '.mcp // []' "$INSTALLED_FILE")
installed_plugins_json=$(jq -c '.external_plugins // []' "$INSTALLED_FILE")
installed_overrides_json=$(jq -c '.command_overrides // []' "$INSTALLED_FILE")
installed_scripts_json=$(jq -c '.scripts // []' "$INSTALLED_FILE")

# 3. New skills (in repo but NOT tracked in installed.json)
# Use is_tracked instead of is_installed to avoid filesystem fallback
# which can find untracked modules left by partial installs
new_skills=()
for d in "$SCRIPT_DIR/skills/"*/; do
    [[ -d "$d" ]] || continue
    name=$(basename "$d")
    if ! is_tracked "skills" "$name"; then
        new_skills+=("$name")
    fi
done

# New MCP servers
new_mcp=()
for f in "$SCRIPT_DIR/mcp/"*.json; do
    [[ -f "$f" ]] || continue
    name=$(basename "$f" .json)
    if ! is_tracked "mcp" "$name"; then
        new_mcp+=("$name")
    fi
done

# 4. New plugins (compare external-plugins.json against installed.json)
new_plugins=()
plugins_config="$SCRIPT_DIR/external-plugins.json"
if [[ -f "$plugins_config" ]]; then
    while IFS= read -r plugin_line; do
        [[ -n "$plugin_line" ]] || continue
        plugin_id=$(echo "$plugin_line" | jq -r '.id')
        marketplace=$(echo "$plugin_line" | jq -r '.marketplace')
        full_id="${plugin_id}@${marketplace}"
        # Check if tracked in installed.json
        if ! jq -e --arg id "$full_id" '.external_plugins // [] | index($id)' "$INSTALLED_FILE" > /dev/null 2>&1; then
            new_plugins+=("$full_id")
        fi
    done < <(jq -c '.plugins[]' "$plugins_config")
fi

# 5. Custom repo status
custom_configured=false
custom_installed=0
custom_available=0
custom_update_available=false

if [[ -d "$CUSTOM_DIR" ]] && [[ -d "$CUSTOM_DIR/.git" ]]; then
    custom_configured=true
    custom_installed=$(jq -r '.custom_version // 0' "$INSTALLED_FILE" 2>/dev/null || echo "0")
    [[ "$custom_installed" =~ ^[0-9]+$ ]] || custom_installed=0

    # Try git fetch to check for updates
    if git -C "$CUSTOM_DIR" fetch --quiet 2>/dev/null; then
        custom_available=$(cat "$CUSTOM_DIR/VERSION" 2>/dev/null || echo "0")
        [[ "$custom_available" =~ ^[0-9]+$ ]] || custom_available=0
        # Check if remote has newer version
        remote_version=$(git -C "$CUSTOM_DIR" show "origin/$(git -C "$CUSTOM_DIR" rev-parse --abbrev-ref HEAD):VERSION" 2>/dev/null || echo "$custom_available")
        [[ "$remote_version" =~ ^[0-9]+$ ]] || remote_version=0
        if [[ "$remote_version" -gt "$custom_installed" ]]; then
            custom_available="$remote_version"
            custom_update_available=true
        fi
    else
        # Remote unreachable — use local VERSION, no update available
        custom_available=$(cat "$CUSTOM_DIR/VERSION" 2>/dev/null || echo "0")
        [[ "$custom_available" =~ ^[0-9]+$ ]] || custom_available=0
    fi

    # Also discover custom skills/MCP not yet installed
    if [[ -d "$CUSTOM_DIR/skills" ]]; then
        for d in "$CUSTOM_DIR/skills/"*/; do
            [[ -d "$d" ]] || continue
            name=$(basename "$d")
            if ! is_installed "skills" "custom:$name"; then
                new_skills+=("custom:$name")
            fi
        done
    fi

    if [[ -d "$CUSTOM_DIR/mcp" ]]; then
        for f in "$CUSTOM_DIR/mcp/"*.json; do
            [[ -f "$f" ]] || continue
            name=$(basename "$f" .json)
            if ! is_installed "mcp" "custom:$name"; then
                new_mcp+=("custom:$name")
            fi
        done
    fi
fi

# 6. Agent Teams status (only "1" or "true" count as enabled)
agent_teams_enabled=false
claude_settings="$CLAUDE_DIR/settings.json"
if [[ -f "$claude_settings" ]]; then
    teams_val=$(jq -r '.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS // ""' "$claude_settings" 2>/dev/null || echo "")
    if [[ "$teams_val" = "1" || "$teams_val" = "true" ]]; then
        agent_teams_enabled=true
    fi
fi

# ============================================
# BUILD JSON OUTPUT
# ============================================

# Convert bash array to JSON array (empty-safe)
array_to_json() {
    if [[ $# -gt 0 ]]; then
        printf '%s\n' "$@" | jq -Rn '[inputs | select(. != "")]'
    else
        echo '[]'
    fi
}

new_skills_json=$(array_to_json "${new_skills[@]+"${new_skills[@]}"}")
new_mcp_json=$(array_to_json "${new_mcp[@]+"${new_mcp[@]}"}")
new_plugins_json=$(array_to_json "${new_plugins[@]+"${new_plugins[@]}"}")

# Build final JSON
jq -n \
    --arg temp_dir "$SCRIPT_DIR" \
    --argjson installed_ver "$installed_version" \
    --argjson available_ver "$available_version" \
    --argjson update_available "$update_available" \
    --argjson custom_configured "$custom_configured" \
    --argjson custom_installed "$custom_installed" \
    --argjson custom_available "$custom_available" \
    --argjson custom_update "$custom_update_available" \
    --argjson installed_skills "$installed_skills_json" \
    --argjson installed_mcp "$installed_mcp_json" \
    --argjson installed_plugins "$installed_plugins_json" \
    --argjson new_skills "$new_skills_json" \
    --argjson new_mcp "$new_mcp_json" \
    --argjson new_plugins "$new_plugins_json" \
    --argjson custom_commands "$installed_overrides_json" \
    --argjson custom_scripts "$installed_scripts_json" \
    --argjson agent_teams "$agent_teams_enabled" \
    '{
        temp_dir: $temp_dir,
        base: {
            installed: $installed_ver,
            available: $available_ver,
            update_available: $update_available
        },
        custom: {
            configured: $custom_configured,
            installed: $custom_installed,
            available: $custom_available,
            update_available: $custom_update,
            commands: $custom_commands,
            scripts: $custom_scripts
        },
        new_modules: {
            skills: $new_skills,
            mcp: $new_mcp,
            plugins: $new_plugins
        },
        installed_modules: {
            skills: $installed_skills,
            mcp: $installed_mcp,
            plugins: $installed_plugins
        },
        agent_teams: {
            enabled: $agent_teams
        }
    }'

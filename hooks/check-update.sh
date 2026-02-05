#!/bin/bash
set -euo pipefail

# Update notification hook for Claude Code Setup
# Runs at session start (startup, clear) to check for available updates
# Output JSON with systemMessage for user-visible notifications; empty output = no notification

installed_json="$HOME/.claude/installed.json"
remote_url="https://raw.githubusercontent.com/b33eep/claude-code-setup/main/templates/VERSION"

# Skip if installed.json doesn't exist (not installed via claude-code-setup)
[[ -f "$installed_json" ]] || exit 0

# === Base repo check (curl to GitHub raw) ===
local_ver=$(jq -r '.content_version // empty' "$installed_json" 2>/dev/null) || true
if [[ -n "$local_ver" ]]; then
    remote_ver=$(curl -fsSL --max-time 2 "$remote_url" 2>/dev/null) || true
    if [[ -n "$remote_ver" && "$remote_ver" =~ ^[0-9]+$ && "$remote_ver" -gt "$local_ver" ]]; then
        echo "{\"systemMessage\": \"Update available: v$local_ver -> v$remote_ver (run /claude-code-setup)\"}"
    fi
fi

# === Custom repo check (VERSION-based, like base repo) ===
custom_dir="$HOME/.claude/custom"
if [[ -d "$custom_dir/.git" ]]; then
    local_custom_ver=$(jq -r '.custom_version // empty' "$installed_json" 2>/dev/null) || true
    if [[ -n "$local_custom_ver" ]]; then
        # Fetch to get latest refs, then read VERSION from remote branch
        git -C "$custom_dir" fetch --quiet origin 2>/dev/null || true
        remote_custom_ver=$(git -C "$custom_dir" show origin/main:VERSION 2>/dev/null) || true
        # Fallback to master if main doesn't exist
        if [[ -z "$remote_custom_ver" ]]; then
            remote_custom_ver=$(git -C "$custom_dir" show origin/master:VERSION 2>/dev/null) || true
        fi
        if [[ -n "$remote_custom_ver" && "$remote_custom_ver" =~ ^[0-9]+$ && "$remote_custom_ver" -gt "$local_custom_ver" ]]; then
            echo "{\"systemMessage\": \"Custom modules update available: v$local_custom_ver -> v$remote_custom_ver (run /claude-code-setup)\"}"
        fi
    fi
fi

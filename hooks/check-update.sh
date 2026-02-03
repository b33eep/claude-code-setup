#!/bin/bash
set -euo pipefail

# Update notification hook for Claude Code Setup
# Runs at session start (startup, clear) to check for available updates
# Output is shown to user; empty output = no notification

installed_json="$HOME/.claude/installed.json"
remote_url="https://raw.githubusercontent.com/b33eep/claude-code-setup/main/templates/VERSION"

# Skip if installed.json doesn't exist (not installed via claude-code-setup)
[[ -f "$installed_json" ]] || exit 0

# === Base repo check (curl to GitHub raw) ===
local_ver=$(jq -r '.content_version // empty' "$installed_json" 2>/dev/null) || true
if [[ -n "$local_ver" ]]; then
    remote_ver=$(curl -fsSL --max-time 2 "$remote_url" 2>/dev/null) || true
    if [[ -n "$remote_ver" && "$remote_ver" =~ ^[0-9]+$ && "$remote_ver" -gt "$local_ver" ]]; then
        echo "Update available: v$local_ver -> v$remote_ver (run /claude-code-setup)"
    fi
fi

# === Custom repo check (git ls-remote, no fetch needed) ===
custom_dir="$HOME/.claude/custom"
if [[ -d "$custom_dir/.git" ]]; then
    local_hash=$(git -C "$custom_dir" rev-parse HEAD 2>/dev/null) || true
    remote_hash=$(git -C "$custom_dir" ls-remote --quiet origin HEAD 2>/dev/null | cut -f1) || true
    if [[ -n "$local_hash" && -n "$remote_hash" && "$local_hash" != "$remote_hash" ]]; then
        echo "Custom modules update available (run /claude-code-setup)"
    fi
fi

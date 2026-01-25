#!/bin/bash
# Quick installer for claude-code-setup
# Usage: curl -fsSL https://raw.githubusercontent.com/b33eep/claude-code-setup/main/quick-install.sh | bash

set -euo pipefail

# Check dependencies
if ! command -v git &>/dev/null; then
    echo "Error: git is required but not installed." >&2
    exit 1
fi

# Allow branch override for testing (default: main)
BRANCH="${CLAUDE_SETUP_BRANCH:-main}"
REPO="${CLAUDE_SETUP_REPO:-b33eep/claude-code-setup}"

echo "Installing claude-code-setup..."
[[ "$BRANCH" != "main" ]] && echo "  (branch: $BRANCH)"
echo ""

temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT

git clone --depth 1 --branch "$BRANCH" "https://github.com/${REPO}.git" "$temp_dir"
cd "$temp_dir"

# Use --yes if not running interactively (no tty)
if [[ -t 0 ]]; then
    ./install.sh
else
    ./install.sh --yes
fi

echo ""
echo "Done! Start Claude Code and run /init-project"

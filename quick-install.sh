#!/bin/bash
# Quick installer for claude-code-setup
# Usage: curl -fsSL https://raw.githubusercontent.com/b33eep/claude-code-setup/main/quick-install.sh | bash

set -euo pipefail

# Check dependencies
if ! command -v git &>/dev/null; then
    echo "Error: git is required but not installed." >&2
    exit 1
fi

echo "Installing claude-code-setup..."
echo ""

temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT

git clone --depth 1 https://github.com/b33eep/claude-code-setup.git "$temp_dir"
cd "$temp_dir"
./install.sh

echo ""
echo "Done! Start Claude Code and run /init-project"

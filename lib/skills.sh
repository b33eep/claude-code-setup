#!/bin/bash

# Skill installation

# Install a single skill
install_skill() {
    local skill_name=$1
    local source_dir=""
    local name
    local target_dir

    if [[ "$skill_name" == custom:* ]]; then
        name="${skill_name#custom:}"
        source_dir="$CUSTOM_DIR/skills/$name"
    else
        source_dir="$SCRIPT_DIR/skills/$skill_name"
    fi

    if [[ ! -d "$source_dir" ]]; then
        print_error "Skill not found: $source_dir"
        return 1
    fi

    target_dir="$CLAUDE_DIR/skills/$(basename "$source_dir")"
    mkdir -p "$CLAUDE_DIR/skills"
    cp -r "$source_dir" "$target_dir"

    return 0
}

# Build CLAUDE.md from template
build_claude_md() {
    # Copy base template (coding standards are now in skills)
    cp "$SCRIPT_DIR/templates/base/global-CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
}

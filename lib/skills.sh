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
    local target="$CLAUDE_DIR/CLAUDE.md"
    local template="$SCRIPT_DIR/templates/base/global-CLAUDE.md"
    local user_file="" default_file=""
    local temp_file="" before_file="" after_file=""
    local has_custom_content=false

    # Cleanup function for temp files
    _cleanup_build_temps() {
        rm -f "$user_file" "$default_file" "$temp_file" "$before_file" "$after_file" 2>/dev/null || true
    }

    # Extract user section if exists (between markers)
    if [[ -f "$target" ]]; then
        user_file=$(mktemp)
        default_file=$(mktemp)

        # Extract user's current section
        sed -n '/<!-- USER INSTRUCTIONS START -->/,/<!-- USER INSTRUCTIONS END -->/p' "$target" > "$user_file" 2>/dev/null || true

        # Extract default section from template for comparison
        sed -n '/<!-- USER INSTRUCTIONS START -->/,/<!-- USER INSTRUCTIONS END -->/p' "$template" > "$default_file" 2>/dev/null || true

        # Check if user has custom content (differs from template default)
        if [[ -s "$user_file" ]] && ! diff -q "$user_file" "$default_file" > /dev/null 2>&1; then
            has_custom_content=true
        fi
    fi

    # Copy base template
    cp "$template" "$target"

    # Re-insert preserved user content if we had custom content
    if [[ "$has_custom_content" = true ]] && [[ -f "$user_file" ]]; then
        temp_file=$(mktemp)
        before_file=$(mktemp)
        after_file=$(mktemp)

        # Extract parts: before section, user section (from file), after section
        awk '/<!-- USER INSTRUCTIONS START -->/{exit} {print}' "$target" > "$before_file"
        awk 'p; /<!-- USER INSTRUCTIONS END -->/{p=1}' "$target" > "$after_file"

        # Combine: before + preserved user section + after
        cat "$before_file" > "$temp_file"
        cat "$user_file" >> "$temp_file"
        cat "$after_file" >> "$temp_file"

        mv "$temp_file" "$target"
    fi

    # Cleanup all temp files
    _cleanup_build_temps
}

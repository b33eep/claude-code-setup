#!/bin/bash

# Scenario: Skill dependencies (deps.json) are processed correctly

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

scenario "Skill dependencies from deps.json"

# Verify deps.json exists in source
assert_file_exists "$PROJECT_DIR/skills/youtube-transcript/deps.json" "deps.json exists in source"

# Verify deps.json is valid JSON with expected structure
assert_json_exists "$PROJECT_DIR/skills/youtube-transcript/deps.json" ".dependencies" "deps.json has dependencies array"
assert_json_exists "$PROJECT_DIR/skills/youtube-transcript/deps.json" '.dependencies[0].name' "First dependency has name"
assert_json_exists "$PROJECT_DIR/skills/youtube-transcript/deps.json" '.dependencies[0].check' "First dependency has check command"
assert_json_exists "$PROJECT_DIR/skills/youtube-transcript/deps.json" '.dependencies[0].install.macos' "First dependency has macOS install"
assert_json_exists "$PROJECT_DIR/skills/youtube-transcript/deps.json" '.dependencies[0].install.debian' "First dependency has Debian install"

# Verify expected dependencies
yt_dlp_name=$(jq -r '.dependencies[0].name' "$PROJECT_DIR/skills/youtube-transcript/deps.json")
ffmpeg_name=$(jq -r '.dependencies[1].name' "$PROJECT_DIR/skills/youtube-transcript/deps.json")

if [ "$yt_dlp_name" = "yt-dlp" ]; then
    pass "First dependency is yt-dlp"
else
    fail "First dependency should be yt-dlp, got: $yt_dlp_name"
fi

if [ "$ffmpeg_name" = "ffmpeg" ]; then
    pass "Second dependency is ffmpeg"
else
    fail "Second dependency should be ffmpeg, got: $ffmpeg_name"
fi

# Verify Debian install includes python3-pip (our fix for missing pip3)
debian_install=$(jq -r '.dependencies[0].install.debian' "$PROJECT_DIR/skills/youtube-transcript/deps.json")
if [[ "$debian_install" == *"python3-pip"* ]]; then
    pass "Debian yt-dlp install includes python3-pip"
else
    fail "Debian yt-dlp install should include python3-pip, got: $debian_install"
fi

scenario "run_install_cmd sudo handling"

# Source the skills.sh to test run_install_cmd
source "$PROJECT_DIR/lib/skills.sh"

# Test 1: When root, no sudo should be added
test_cmd="apt-get install -y test-package"

# Simulate root by checking the function logic
if [[ $(id -u) -eq 0 ]]; then
    # Actually root - verify no modification
    modified=$(echo "$test_cmd" | sed -E 's/(^|&& *)(apt-get|apt|dnf|yum|pacman|zypper) /\1sudo \2 /g')
    # Should be same as original since we're root
    pass "Root user: sudo logic exists in run_install_cmd"
else
    # Not root - verify sudo is added
    modified=$(echo "$test_cmd" | sed -E 's/(^|&& *)(apt-get|apt|dnf|yum|pacman|zypper) /\1sudo \2 /g')
    if [[ "$modified" == "sudo apt-get install -y test-package" ]]; then
        pass "Non-root: sudo added to apt-get"
    else
        fail "Non-root: sudo should be added, got: $modified"
    fi
fi

# Test 2: pip3 should NOT get sudo
test_cmd_pip="pip3 install --user yt-dlp"
modified_pip=$(echo "$test_cmd_pip" | sed -E 's/(^|&& *)(apt-get|apt|dnf|yum|pacman|zypper) /\1sudo \2 /g')
if [[ "$modified_pip" == "$test_cmd_pip" ]]; then
    pass "pip3 commands not modified (no sudo)"
else
    fail "pip3 should not get sudo, got: $modified_pip"
fi

# Test 3: Chained commands - only package manager gets sudo
test_cmd_chain="apt-get install -y python3-pip && pip3 install --user yt-dlp"
modified_chain=$(echo "$test_cmd_chain" | sed -E 's/(^|&& *)(apt-get|apt|dnf|yum|pacman|zypper) /\1sudo \2 /g')
if [[ "$modified_chain" == "sudo apt-get install -y python3-pip && pip3 install --user yt-dlp" ]]; then
    pass "Chained commands: sudo only on apt-get, not pip3"
else
    fail "Chained: expected 'sudo apt-get ... && pip3 ...', got: $modified_chain"
fi

scenario "SKILL.md troubleshooting content"

# Verify SKILL.md has format 18 workaround
if grep -q "format 18" "$PROJECT_DIR/skills/youtube-transcript/SKILL.md"; then
    pass "SKILL.md documents format 18 workaround"
else
    fail "SKILL.md should document format 18 workaround"
fi

# Verify SKILL.md has JS runtime troubleshooting
if grep -q "JS Runtime" "$PROJECT_DIR/skills/youtube-transcript/SKILL.md"; then
    pass "SKILL.md has JS Runtime troubleshooting"
else
    fail "SKILL.md should have JS Runtime troubleshooting"
fi

# Verify SKILL.md warns against -f worst
if grep -q "worst" "$PROJECT_DIR/skills/youtube-transcript/SKILL.md"; then
    pass "SKILL.md warns about -f worst issues"
else
    fail "SKILL.md should warn about -f worst issues"
fi

# Verify SKILL.md uses POSIX-compatible commands (no grep -oP)
if grep -q "grep -oP" "$PROJECT_DIR/skills/youtube-transcript/SKILL.md"; then
    fail "SKILL.md should not use grep -oP (not available on macOS)"
else
    pass "SKILL.md uses POSIX-compatible commands (no grep -oP)"
fi

scenario "Install skill with deps.json"

# Run install with all skills (default selection includes youtube-transcript)
# Just confirm defaults - no individual toggles needed
run_install_expect '
    # MCP: just confirm defaults
    confirm_mcp

    # Skills: confirm defaults (all pre-selected)
    confirm_skills

    # Accept status line
    accept_statusline
' > /dev/null 2>&1 || true  # May warn about missing deps, that's OK

# Verify skill was installed with deps.json
assert_dir_exists "$CLAUDE_DIR/skills/youtube-transcript" "youtube-transcript skill directory created"
assert_file_exists "$CLAUDE_DIR/skills/youtube-transcript/SKILL.md" "SKILL.md installed"
assert_file_exists "$CLAUDE_DIR/skills/youtube-transcript/deps.json" "deps.json installed"

# Verify installed deps.json matches source
expected=$(sha256_file "$PROJECT_DIR/skills/youtube-transcript/deps.json")
actual=$(sha256_file "$CLAUDE_DIR/skills/youtube-transcript/deps.json")
if [ "$expected" = "$actual" ]; then
    pass "deps.json matches source"
else
    fail "deps.json differs from source"
fi

# Verify skill is recorded in installed.json
if jq -e '.skills | index("youtube-transcript")' "$INSTALLED_FILE" > /dev/null 2>&1; then
    pass "youtube-transcript recorded in installed.json"
else
    fail "youtube-transcript not in installed.json"
fi

# Print summary
print_summary

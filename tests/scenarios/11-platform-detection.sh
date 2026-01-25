#!/bin/bash

# Scenario: Platform detection

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

# Source platform module directly for testing
# shellcheck source=../../lib/helpers.sh
source "$PROJECT_DIR/lib/helpers.sh"
# shellcheck source=../../lib/platform.sh
source "$PROJECT_DIR/lib/platform.sh"

scenario "Platform detection on current OS"

detect_os

if [[ -n "$OS_TYPE" ]]; then
    pass "OS_TYPE is set: $OS_TYPE"
else
    fail "OS_TYPE is not set"
fi

if [[ "$OS_TYPE" =~ ^(macos|linux)$ ]]; then
    pass "OS_TYPE is valid (macos or linux)"
else
    fail "OS_TYPE has unexpected value: $OS_TYPE"
fi

scenario "Package manager detection"

pkg_manager=$(get_package_manager_name)

if [[ -n "$pkg_manager" ]]; then
    pass "Package manager detected: $pkg_manager"
else
    fail "Package manager not detected"
fi

scenario "OS display name"

os_name=$(get_os_display_name)

if [[ -n "$os_name" ]]; then
    pass "OS display name: $os_name"
else
    fail "OS display name not set"
fi

scenario "Package manager check passes"

# This should not exit (package manager should exist on test system)
if check_package_manager 2>/dev/null; then
    pass "check_package_manager passes"
else
    fail "check_package_manager failed"
fi

scenario "Distro detection helper (Linux only)"

if [[ "$OS_TYPE" = "linux" ]]; then
    distro=$(detect_distro_by_package_manager)
    if [[ -n "$distro" ]]; then
        pass "Distro detected by package manager: $distro"
    else
        fail "Distro detection failed"
    fi

    if [[ -n "$LINUX_DISTRO" ]]; then
        pass "LINUX_DISTRO is set: $LINUX_DISTRO"
    else
        fail "LINUX_DISTRO is not set"
    fi
else
    pass "Skipped (not Linux)"
    pass "Skipped (not Linux)"
fi

scenario "WSL detection"

if [[ "$OS_TYPE" = "linux" ]]; then
    if [[ "$IS_WSL" = true ]]; then
        pass "WSL detected: true"
    else
        pass "WSL detected: false (not running in WSL)"
    fi
else
    pass "Skipped (not Linux)"
fi

# Print summary
print_summary

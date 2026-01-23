#!/bin/bash

# Test helper functions

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Counters
TESTS_PASSED=0
TESTS_FAILED=0

# Setup test environment
setup_test_env() {
    export TEST_DIR="/tmp/claude-test-$$"
    export CLAUDE_DIR="$TEST_DIR/.claude"
    export CUSTOM_DIR="$CLAUDE_DIR/custom"
    export INSTALLED_FILE="$CLAUDE_DIR/installed.json"
    export MCP_CONFIG_FILE="$TEST_DIR/.claude.json"

    mkdir -p "$CLAUDE_DIR"
    echo "Test environment: $TEST_DIR"
}

# Cleanup test environment
cleanup_test_env() {
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

# Assert file exists
assert_file_exists() {
    local file=$1
    local msg=${2:-"File exists: $file"}
    if [ -f "$file" ]; then
        pass "$msg"
    else
        fail "$msg (not found)"
    fi
    return 0
}

# Assert directory exists
assert_dir_exists() {
    local dir=$1
    local msg=${2:-"Directory exists: $dir"}
    if [ -d "$dir" ]; then
        pass "$msg"
    else
        fail "$msg (not found)"
    fi
    return 0
}

# Assert file contains string
assert_file_contains() {
    local file=$1
    local pattern=$2
    local msg=${3:-"File contains: $pattern"}
    if grep -q "$pattern" "$file" 2>/dev/null; then
        pass "$msg"
    else
        fail "$msg (pattern not found in $file)"
    fi
    return 0
}

# Assert JSON field equals value
assert_json_eq() {
    local file=$1
    local field=$2
    local expected=$3
    local msg=${4:-"JSON $field == $expected"}
    local actual
    actual=$(jq -r "$field" "$file" 2>/dev/null) || actual="(error)"
    if [ "$actual" = "$expected" ]; then
        pass "$msg"
    else
        fail "$msg (got: $actual)"
    fi
    return 0
}

# Assert JSON field exists
assert_json_exists() {
    local file=$1
    local field=$2
    local msg=${3:-"JSON field exists: $field"}
    if jq -e "$field" "$file" > /dev/null 2>&1; then
        pass "$msg"
    else
        fail "$msg (field not found)"
    fi
    return 0
}

# Assert command succeeds
assert_cmd() {
    local msg=$1
    shift
    if "$@" > /dev/null 2>&1; then
        pass "$msg"
    else
        fail "$msg (command failed: $*)"
    fi
    return 0
}

# Assert command output contains
assert_output_contains() {
    local msg=$1
    local pattern=$2
    shift 2
    local output
    output=$("$@" 2>&1) || true
    if echo "$output" | grep -q "$pattern"; then
        pass "$msg"
    else
        fail "$msg (pattern '$pattern' not in output)"
    fi
    return 0
}

# Pass a test
pass() {
    echo -e "  ${GREEN}✓${NC} $1"
    ((TESTS_PASSED++)) || true
}

# Fail a test
fail() {
    echo -e "  ${RED}✗${NC} $1"
    ((TESTS_FAILED++)) || true
}

# Print scenario header
scenario() {
    echo ""
    echo -e "${YELLOW}▶ $1${NC}"
}

# Print test summary
print_summary() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC} ($TESTS_PASSED passed)"
    else
        echo -e "${RED}Tests failed!${NC} ($TESTS_PASSED passed, $TESTS_FAILED failed)"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    return "$TESTS_FAILED"
}

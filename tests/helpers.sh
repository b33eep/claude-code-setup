#!/bin/bash

# Test helper functions

# ============================================
# EXPECT HELPERS
# ============================================

# Shared expect procedures (embedded in each function to avoid file dependencies)
# These procedures are used across run_install_expect, run_add_expect, run_update_expect
#
# Available procedures:
#   toggle_mcp <num>      - Toggle MCP server by number (1-based)
#   confirm_mcp           - Press Enter to confirm MCP selection
#   toggle_skill <num>    - Toggle skill by number (1-based)
#   confirm_skills        - Press Enter to confirm skills selection
#   deselect_all_mcp      - Deselect all MCP servers (toggle each one that's selected)
#   deselect_all_skills   - Deselect all skills (toggle each one that's selected)
#   select_only_skill <n> - Deselect all skills except number n
#   accept_statusline     - Accept status line with Y
#   decline_statusline    - Decline status line with n
#   enter_api_key <key>   - Enter an API key
#   confirm_update        - Confirm update prompt (--update mode)
#   confirm_defaults      - Confirm both MCP and Skills with defaults

# Common expect procs - shared across all expect functions
# Note: This is defined as a variable to avoid duplication
# shellcheck disable=SC2016  # Intentional: $variables are for expect/Tcl, not bash
_EXPECT_COMMON_PROCS='
        # Toggle MCP server by number, handles fresh install prompt
        proc toggle_mcp {num} {
            expect {
                {Continue with fresh install?} { send "y\n"; sleep 0.1; exp_continue }
                -re {Toggle \(1-\d+\)} { send "$num\n"; sleep 0.1 }
                timeout { puts "TIMEOUT at MCP toggle"; exit 1 }
            }
        }

        # Confirm MCP selection (press Enter)
        proc confirm_mcp {} {
            expect {
                {Continue with fresh install?} { send "y\n"; sleep 0.1; exp_continue }
                -re {Toggle \(1-\d+\)} { send "\n"; sleep 0.1 }
                timeout { puts "TIMEOUT at MCP confirm"; exit 1 }
            }
        }

        # Toggle skill by number
        proc toggle_skill {num} {
            expect {
                -re {Toggle \(1-\d+\)} { send "$num\n"; sleep 0.1 }
                timeout { puts "TIMEOUT at Skill toggle"; exit 1 }
            }
        }

        # Confirm skills selection (press Enter)
        proc confirm_skills {} {
            expect {
                -re {Toggle \(1-\d+\)} { send "\n"; sleep 0.1 }
                timeout { puts "TIMEOUT at Skills confirm"; exit 1 }
            }
        }

        # Select all skills (press a)
        proc select_all_skills {} {
            expect {
                -re {Toggle \(1-\d+\)} { send "a\n"; sleep 0.1 }
                timeout { puts "TIMEOUT at select all skills"; exit 1 }
            }
        }

        # Deselect pre-selected MCP (pdf-reader at position 3) and confirm
        # MCP order (alphabetical): 1=brave-search, 2=google-search, 3=pdf-reader
        # Only pdf-reader is pre-selected by default
        proc deselect_all_mcp {} {
            expect {
                {Continue with fresh install?} { send "y\n"; sleep 0.1; exp_continue }
                -re {Toggle \(1-(\d+)\)} {
                    # Toggle pdf-reader OFF (position 3) then confirm
                    send "3\n"
                    sleep 0.1
                    expect -re {Toggle|Selected}
                    send "\n"
                    sleep 0.1
                }
                timeout { puts "TIMEOUT at deselect all MCP"; exit 1 }
            }
        }

        # Deselect all skills (for fresh install where all are pre-selected)
        # Dynamically determines count from prompt
        proc deselect_all_skills {} {
            expect {
                -re {Toggle \(1-(\d+)\)} {
                    set count $expect_out(1,string)
                    for {set i 1} {$i <= $count} {incr i} {
                        send "$i\n"
                        sleep 0.1
                        expect -re {Toggle|Selected}
                    }
                    send "\n"
                    sleep 0.1
                }
                timeout { puts "TIMEOUT at deselect all skills"; exit 1 }
            }
        }

        # Select only skill number n (deselects all others)
        # All skills are pre-selected by default, so toggle all except n
        proc select_only_skill {keep} {
            expect {
                -re {Toggle \(1-(\d+)\)} {
                    set count $expect_out(1,string)
                    for {set i 1} {$i <= $count} {incr i} {
                        if {$i != $keep} {
                            send "$i\n"
                            sleep 0.1
                            expect -re {Toggle|Selected}
                        }
                    }
                    send "\n"
                    sleep 0.1
                }
                timeout { puts "TIMEOUT at select only skill"; exit 1 }
            }
        }

        # Accept status line prompt with Y
        proc accept_statusline {} {
            expect {
                {Enable context status line} { send "Y\n"; sleep 0.1 }
                timeout { puts "TIMEOUT at status line"; exit 1 }
            }
        }

        # Decline status line prompt with n
        proc decline_statusline {} {
            expect {
                {Enable context status line} { send "n\n"; sleep 0.1 }
                timeout { puts "TIMEOUT at status line"; exit 1 }
            }
        }

        # Enter API key when prompted
        proc enter_api_key {key} {
            expect {
                {Enter your} { send "$key\n"; sleep 0.1 }
                timeout { puts "TIMEOUT at API key"; exit 1 }
            }
        }

        # Confirm update prompt (for --update mode)
        proc confirm_update {} {
            expect {
                {Proceed?} { send "y\n"; sleep 0.1 }
                timeout { puts "TIMEOUT at update confirm"; exit 1 }
            }
        }

        # Confirm both MCP and Skills with defaults
        proc confirm_defaults {} {
            confirm_mcp
            confirm_skills
        }
'

# Run install.sh with expect-based interactive input
# Usage: run_install_expect <expect_commands>
# Example: run_install_expect 'confirm_mcp; select_only_skill 4; accept_statusline'
run_install_expect() {
    local expect_body=$1
    local project_dir=${2:-$PROJECT_DIR}

    expect -c "
        set timeout 30
        set env(HOME) \"$TEST_DIR\"
        set env(CLAUDE_DIR) \"$CLAUDE_DIR\"
        set env(MCP_CONFIG_FILE) \"$MCP_CONFIG_FILE\"
        set env(TERM) \"xterm-256color\"

        $_EXPECT_COMMON_PROCS

        spawn $project_dir/install.sh

        $expect_body

        expect eof
    " 2>&1
}

# Run install.sh --add with expect
run_add_expect() {
    local expect_body=$1
    local project_dir=${2:-$PROJECT_DIR}

    expect -c "
        set timeout 30
        set env(HOME) \"$TEST_DIR\"
        set env(CLAUDE_DIR) \"$CLAUDE_DIR\"
        set env(MCP_CONFIG_FILE) \"$MCP_CONFIG_FILE\"
        set env(TERM) \"xterm-256color\"

        $_EXPECT_COMMON_PROCS

        spawn $project_dir/install.sh --add

        $expect_body

        expect eof
    " 2>&1
}

# Run install.sh --update with expect
run_update_expect() {
    local expect_body=$1
    local project_dir=${2:-$PROJECT_DIR}

    expect -c "
        set timeout 30
        set env(HOME) \"$TEST_DIR\"
        set env(CLAUDE_DIR) \"$CLAUDE_DIR\"
        set env(MCP_CONFIG_FILE) \"$MCP_CONFIG_FILE\"
        set env(TERM) \"xterm-256color\"

        $_EXPECT_COMMON_PROCS

        spawn $project_dir/install.sh --update

        $expect_body

        expect eof
    " 2>&1
}

# ============================================
# SHA256 HELPER
# ============================================

# Cross-platform SHA256 function
# Usage: sha256_file <file>
# Returns: hash (first field only)
sha256_file() {
    local file=$1
    if command -v shasum &>/dev/null; then
        # macOS
        shasum -a 256 "$file" | cut -d' ' -f1
    elif command -v sha256sum &>/dev/null; then
        # Linux
        sha256sum "$file" | cut -d' ' -f1
    else
        echo "ERROR: No sha256 tool found" >&2
        return 1
    fi
}

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

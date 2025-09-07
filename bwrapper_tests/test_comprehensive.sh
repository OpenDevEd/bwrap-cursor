#!/usr/bin/env bash
# Comprehensive test suite for bwrapper with multiple options testing

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PASSED=0
FAILED=0
TOTAL=0

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BWRAPPER="$PROJECT_ROOT/bwrapper"

print_result() {
    local test_name="$1"
    local result="$2"
    local details="$3"
    
    ((TOTAL++))
    if [ "$result" = "PASS" ]; then
        ((PASSED++))
        echo -e "${GREEN}✅ $test_name: PASS${NC}"
    else
        ((FAILED++))
        echo -e "${RED}❌ $test_name: FAIL${NC}"
        if [ -n "$details" ]; then
            echo -e "${YELLOW}   Details: $details${NC}"
        fi
    fi
}

test_dryrun() {
    local test_name="$1"
    local expected_patterns=("${@:2}")
    shift 2
    local command=("$@")
    
    echo -e "${BLUE}Testing: $test_name${NC}"
    
    local output
    if output=$("${command[@]}" 2>&1); then
        local all_found=true
        local missing_patterns=()
        
        for pattern in "${expected_patterns[@]}"; do
            if ! echo "$output" | grep -q "$pattern"; then
                all_found=false
                missing_patterns+=("$pattern")
            fi
        done
        
        if [ "$all_found" = true ]; then
            print_result "$test_name" "PASS" ""
        else
            print_result "$test_name" "FAIL" "Missing patterns: ${missing_patterns[*]}"
        fi
    else
        print_result "$test_name" "FAIL" "Command failed with exit code $?"
    fi
}

test_command() {
    local test_name="$1"
    local expected_pattern="$2"
    shift 2
    local command=("$@")
    
    echo -e "${BLUE}Testing: $test_name${NC}"
    
    local output
    if output=$("${command[@]}" 2>&1); then
        if echo "$output" | grep -q "$expected_pattern"; then
            print_result "$test_name" "PASS" ""
        else
            print_result "$test_name" "FAIL" "Expected pattern '$expected_pattern' not found"
        fi
    else
        print_result "$test_name" "FAIL" "Command failed with exit code $?"
    fi
}

echo -e "${CYAN}=== Comprehensive bwrapper Test Suite ===${NC}"
echo -e "${BLUE}Testing from: $SCRIPT_DIR${NC}"
echo -e "${BLUE}Project root: $PROJECT_ROOT${NC}"
echo -e "${BLUE}bwrapper path: $BWRAPPER${NC}"
echo

# Test 1: Basic functionality
echo -e "${CYAN}=== Basic Functionality Tests ===${NC}"

test_command "Help command" "bwrapper — Generic bwrap sandboxing helper with configuration support" \
    "$BWRAPPER" --help

test_command "List configurations" "Available configurations:" \
    "$BWRAPPER" --list

test_dryrun "Basic dryrun" \
    "bwrap" "--ro-bind" "/" "/" "--proc" "/proc" "--dev" "/dev" \
    "$BWRAPPER" --dryrun cursor

# Test 2: Single CLI arguments
echo -e "${CYAN}=== Single CLI Arguments Tests ===${NC}"

test_dryrun "Single --arg" \
    "bwrap" "--ro-bind" "/" "/" "--proc" "/proc" "--dev" "/dev" \
    "$BWRAPPER" --exec /usr/bin/echo --arg hello --dryrun world

test_dryrun "Single --rw" \
    "bwrap" "--ro-bind" "/" "/" "--proc" "/proc" "--dev" "/dev" \
    "$BWRAPPER" --exec /usr/bin/echo --rw /tmp/test --dryrun hello

test_dryrun "Single --env" \
    "bwrap" "--ro-bind" "/" "/" "--proc" "/proc" "--dev" "/dev" \
    "$BWRAPPER" --exec /usr/bin/echo --env TEST_VAR=hello --dryrun test

# Test 3: Multiple --arg options
echo -e "${CYAN}=== Multiple --arg Options Tests ===${NC}"

test_dryrun "Multiple --arg (find example)" \
    "bwrap" "--ro-bind" "/" "/" "--proc" "/proc" "--dev" "/dev" \
    "$BWRAPPER" --exec bash --arg find --arg . --dryrun path1 path2

test_dryrun "Multiple --arg (grep example)" \
    "bwrap" "--ro-bind" "/" "/" "--proc" "/proc" "--dev" "/dev" \
    "$BWRAPPER" --exec grep --arg -r --arg -n --arg pattern --dryrun file1 file2

test_dryrun "Multiple --arg (ls example)" \
    "bwrap" "--ro-bind" "/" "/" "--proc" "/proc" "--dev" "/dev" \
    "$BWRAPPER" --exec ls --arg -la --arg -h --arg --color=auto --dryrun /tmp

# Test 4: Multiple --rw options
echo -e "${CYAN}=== Multiple --rw Options Tests ===${NC}"

test_dryrun "Multiple --rw (basic)" \
    "bwrap" "--ro-bind" "/" "/" "--proc" "/proc" "--dev" "/dev" \
    "$BWRAPPER" --exec /usr/bin/echo --rw /tmp/test1 --rw /tmp/test2 --dryrun hello

test_dryrun "Multiple --rw (cursor-like)" \
    "bwrap" "--ro-bind" "/" "/" "--proc" "/proc" "--dev" "/dev" \
    "$BWRAPPER" --exec /usr/bin/echo --rw /tmp/.config --rw /tmp/.cache --rw /tmp/.local --dryrun test

test_dryrun "Multiple --rw (development)" \
    "bwrap" "--ro-bind" "/" "/" "--proc" "/proc" "--dev" "/dev" \
    "$BWRAPPER" --exec /usr/bin/echo --rw /tmp/project1 --rw /tmp/project2 --rw /tmp/project3 --dryrun build

# Test 5: Multiple --env options
echo -e "${CYAN}=== Multiple --env Options Tests ===${NC}"

test_dryrun "Multiple --env" \
    "bwrap" "--ro-bind" "/" "/" "--proc" "/proc" "--dev" "/dev" \
    "$BWRAPPER" --exec /usr/bin/echo --env TEST_VAR1=hello --env TEST_VAR2=world --env DEBUG=1 --dryrun test

# Test 6: Combined multiple options
echo -e "${CYAN}=== Combined Multiple Options Tests ===${NC}"

test_dryrun "Multiple --arg + --rw" \
    "bwrap" "--ro-bind" "/" "/" "--proc" "/proc" "--dev" "/dev" \
    "$BWRAPPER" --exec bash --arg find --arg . --arg -name --arg "*.txt" --rw /tmp/output --rw /tmp/logs --dryrun /tmp

test_dryrun "Multiple --arg + --env" \
    "bwrap" "--ro-bind" "/" "/" "--proc" "/proc" "--dev" "/dev" \
    "$BWRAPPER" --exec python --arg -c --arg "print('hello')" --env PYTHONPATH=/tmp --env DEBUG=1 --dryrun test

test_dryrun "All multiple options" \
    "bwrap" "--ro-bind" "/" "/" "--proc" "/proc" "--dev" "/dev" \
    "$BWRAPPER" --exec bash --arg find --arg . --arg -type --arg f --rw /tmp/results --rw /tmp/temp --env SEARCH_PATH=/tmp --env OUTPUT_FORMAT=json --dryrun /tmp

# Test 7: Home isolation with multiple options
echo -e "${CYAN}=== Home Isolation with Multiple Options Tests ===${NC}"

test_dryrun "Home isolation + multiple --arg" \
    "bwrap" "--ro-bind" "/" "/" "--tmpfs" "/home" "--setenv" "HOME" "/home/app" \
    "$BWRAPPER" --exec bash --home /tmp/test-home --arg find --arg . --arg -name --arg "*.txt" --dryrun path1 path2

test_dryrun "Home isolation + multiple --rw" \
    "bwrap" "--ro-bind" "/" "/" "--tmpfs" "/home" "--setenv" "HOME" "/home/app" \
    "$BWRAPPER" --exec /usr/bin/echo --home /tmp/test-home --rw /tmp/config --rw /tmp/cache --dryrun hello

test_dryrun "Home isolation + work + multiple options" \
    "bwrap" "--ro-bind" "/" "/" "--tmpfs" "/home" "--setenv" "HOME" "/home/app" \
    "$BWRAPPER" --exec bash --home /tmp/test-home --work projects --arg find --arg . --arg -type --arg d --rw /tmp/results --dryrun path1 path2

# Test 8: Error handling
echo -e "${CYAN}=== Error Handling Tests ===${NC}"

test_command "Missing configuration error" "Configuration file not found" \
    "$BWRAPPER" --dryrun nonexistent_config 2>/dev/null || true

test_command "Invalid CLI options error" "Error:" \
    "$BWRAPPER" --arg test --dryrun test 2>/dev/null || true

# Test 9: Save configuration with multiple options
echo -e "${CYAN}=== Save Configuration with Multiple Options Tests ===${NC}"

test_command "Save configuration with multiple options" "Configuration saved to:" \
    "$BWRAPPER" --exec /usr/bin/echo --arg test1 --arg test2 --rw /tmp/test1 --rw /tmp/test2 --env VAR1=val1 --env VAR2=val2 --save test_multiple_config

# Verify the saved configuration exists
if [ -f "$PROJECT_ROOT/configurations/test_multiple_config.conf" ]; then
    print_result "Saved configuration file exists" "PASS" ""
    
    # Test using saved configuration
    test_dryrun "Use saved configuration with multiple options" \
        "bwrap" "--ro-bind" "/" "/" "--proc" "/proc" "--dev" "/dev" \
        "$BWRAPPER" --dryrun test_multiple_config
    
    # Clean up test configuration
    rm -f "$PROJECT_ROOT/configurations/test_multiple_config.conf"
else
    print_result "Saved configuration file exists" "FAIL" "Configuration file not created"
fi

# Print final results
echo
echo -e "${CYAN}=== Test Results ===${NC}"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo -e "${YELLOW}Total:  $TOTAL${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Some tests failed!${NC}"
    exit 1
fi

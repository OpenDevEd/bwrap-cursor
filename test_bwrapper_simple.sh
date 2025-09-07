#!/usr/bin/env bash
# Simple and robust test suite for bwrapper

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0

print_result() {
    local test_name="$1"
    local result="$2"
    local details="$3"
    
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

echo -e "${BLUE}Starting bwrapper test suite...${NC}"
echo

# Test 1: Help command
test_command "Help command" "bwrapper — Generic bwrap sandboxing helper with configuration support" \
    ./bwrapper --help

# Test 2: List configurations
test_command "List configurations" "Available configurations:" \
    ./bwrapper --list

# Test 3: Basic dryrun
test_command "Basic dryrun" "bwrap" \
    ./bwrapper --dryrun cursor

# Test 4: CLI with your specific example
test_command "CLI with find arguments" "bwrap" \
    ./bwrapper --exec bash --arg find --arg . --dryrun path1 path2

# Test 5: CLI with read-write paths
test_command "CLI with read-write paths" "bwrap" \
    ./bwrapper --exec /usr/bin/echo --rw /tmp/test --dryrun hello

# Test 6: CLI with environment variables
test_command "CLI with environment variables" "bwrap" \
    ./bwrapper --exec /usr/bin/echo --env TEST_VAR=hello --dryrun test

# Test 7: Home isolation
test_command "Home isolation" "tmpfs" \
    ./bwrapper --exec /usr/bin/echo --home /tmp/test-home --dryrun hello

# Test 8: Home isolation with work directory
test_command "Home isolation with work" "tmpfs" \
    ./bwrapper --exec /usr/bin/echo --home /tmp/test-home --work projects --dryrun path1 path2

# Test 9: Save configuration
test_command "Save configuration" "Configuration saved to:" \
    ./bwrapper --exec /usr/bin/echo --arg test --rw /tmp/test --save test_config

# Test 10: Use saved configuration
if [ -f "./configurations/test_config.conf" ]; then
    test_command "Use saved configuration" "bwrap" \
        ./bwrapper --dryrun test_config
    
    # Clean up
    rm -f "./configurations/test_config.conf"
else
    print_result "Use saved configuration" "FAIL" "Configuration file not created"
fi

# Test 11: Error handling - missing config
test_command "Missing configuration error" "Configuration file not found" \
    ./bwrapper --dryrun nonexistent_config 2>/dev/null || true

# Test 12: Error handling - invalid CLI options
test_command "Invalid CLI options error" "Error:" \
    ./bwrapper --arg test --dryrun test 2>/dev/null || true

echo
echo -e "${BLUE}=== TEST RESULTS ===${NC}"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo -e "${YELLOW}Total:  $((PASSED + FAILED))${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Some tests failed!${NC}"
    exit 1
fi

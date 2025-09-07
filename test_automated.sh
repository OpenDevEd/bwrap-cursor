#!/usr/bin/env bash
# Automated test for bwrapper with validation

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
    
    if [ "$result" = "PASS" ]; then
        ((PASSED++))
        echo -e "${GREEN}✅ $test_name: PASS${NC}"
    else
        ((FAILED++))
        echo -e "${RED}❌ $test_name: FAIL${NC}"
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
        for pattern in "${expected_patterns[@]}"; do
            if ! echo "$output" | grep -q "$pattern"; then
                all_found=false
                break
            fi
        done
        
        if [ "$all_found" = true ]; then
            print_result "$test_name" "PASS"
        else
            print_result "$test_name" "FAIL"
        fi
    else
        print_result "$test_name" "FAIL"
    fi
}

echo -e "${BLUE}=== Automated bwrapper Test Suite ===${NC}"
echo

# Test 1: Your specific example
test_dryrun "CLI with find arguments" \
    "bwrap" "--ro-bind" "/" "/" "--proc" "/proc" "--dev" "/dev" \
    ./bwrapper --exec bash --arg find --arg . --dryrun path1 path2

# Test 2: Basic dryrun
test_dryrun "Basic dryrun" \
    "bwrap" "--ro-bind" "/" "/" "--proc" "/proc" "--dev" "/dev" \
    ./bwrapper --dryrun cursor

# Test 3: Home isolation
test_dryrun "Home isolation" \
    "bwrap" "--ro-bind" "/" "/" "--tmpfs" "/home" "--setenv" "HOME" "/home/app" \
    ./bwrapper --exec /usr/bin/echo --home /tmp/test-home --dryrun hello

# Test 4: CLI with read-write paths
test_dryrun "CLI with read-write paths" \
    "bwrap" "--ro-bind" "/" "/" "--bind" "/tmp/test" \
    ./bwrapper --exec /usr/bin/echo --rw /tmp/test --dryrun hello

# Test 5: CLI with environment variables
test_dryrun "CLI with environment variables" \
    "bwrap" "--ro-bind" "/" "/" "--setenv" "TEST_VAR" "hello" \
    ./bwrapper --exec /usr/bin/echo --env TEST_VAR=hello --dryrun test

# Test 6: Help command
test_dryrun "Help command" \
    "bwrapper — Generic bwrap sandboxing helper with configuration support" \
    ./bwrapper --help

# Test 7: List configurations
test_dryrun "List configurations" \
    "Available configurations:" \
    ./bwrapper --list

echo
echo -e "${BLUE}=== Test Results ===${NC}"
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

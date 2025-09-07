#!/usr/bin/env bash
# test_bwrapper.sh — Comprehensive test suite for bwrapper
# Usage:
#   ./test_bwrapper.sh              # Run all tests
#   ./test_bwrapper.sh --verbose    # Run with verbose output
#   ./test_bwrapper.sh --help       # Show help

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test configuration
VERBOSE=false
TEST_DIR="/tmp/bwrapper_test_$$"
PASSED=0
FAILED=0
TOTAL=0

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print test header
print_test_header() {
    local test_name=$1
    echo
    print_color $CYAN "=== $test_name ==="
}

# Function to print test result
print_test_result() {
    local test_name=$1
    local result=$2
    local details=$3
    
    ((TOTAL++))
    if [ "$result" = "PASS" ]; then
        ((PASSED++))
        print_color $GREEN "✅ $test_name: PASS"
    else
        ((FAILED++))
        print_color $RED "❌ $test_name: FAIL"
        if [ -n "$details" ]; then
            print_color $YELLOW "   Details: $details"
        fi
    fi
    
    if [ "$VERBOSE" = true ]; then
        echo "   Total tests: $TOTAL | Passed: $PASSED | Failed: $FAILED"
    fi
}

# Function to run a test command and capture output
run_test_command() {
    local test_name=$1
    local expected_pattern=$2
    local command=("${@:3}")
    
    print_test_header "$test_name"
    
    if [ "$VERBOSE" = true ]; then
        print_color $BLUE "Running: ${command[*]}"
    fi
    
    local output
    local exit_code=0
    
    if output=$("${command[@]}" 2>&1); then
        exit_code=0
    else
        exit_code=$?
    fi
    
    if echo "$output" | grep -q "$expected_pattern"; then
        print_test_result "$test_name" "PASS" ""
        if [ "$VERBOSE" = true ]; then
            echo "Output: $output"
        fi
    else
        print_test_result "$test_name" "FAIL" "Expected pattern '$expected_pattern' not found in output"
        if [ "$VERBOSE" = true ]; then
            echo "Output: $output"
        fi
    fi
}

# Function to test dryrun output
test_dryrun_output() {
    local test_name=$1
    local expected_patterns=("${@:2}")
    local command=("${@:3}")
    
    print_test_header "$test_name"
    
    if [ "$VERBOSE" = true ]; then
        print_color $BLUE "Running: ${command[*]}"
    fi
    
    local output
    local exit_code=0
    
    if output=$("${command[@]}" 2>&1); then
        exit_code=0
    else
        exit_code=$?
    fi
    
    local all_patterns_found=true
    local missing_patterns=()
    
    for pattern in "${expected_patterns[@]}"; do
        if ! echo "$output" | grep -q "$pattern"; then
            all_patterns_found=false
            missing_patterns+=("$pattern")
        fi
    done
    
    if [ "$all_patterns_found" = true ]; then
        print_test_result "$test_name" "PASS" ""
        if [ "$VERBOSE" = true ]; then
            echo "Output: $output"
        fi
    else
        print_test_result "$test_name" "FAIL" "Missing patterns: ${missing_patterns[*]}"
        if [ "$VERBOSE" = true ]; then
            echo "Output: $output"
        fi
    fi
}

# Function to setup test environment
setup_test_environment() {
    print_color $BLUE "Setting up test environment..."
    
    # Create test directory
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"
    
    # Create test files and directories
    mkdir -p path1 path2 path3
    echo "test file 1" > path1/file1.txt
    echo "test file 2" > path2/file2.txt
    echo "test file 3" > path3/file3.txt
    
    # Create a test home directory
    mkdir -p test-home
    
    print_color $GREEN "Test environment ready at: $TEST_DIR"
}

# Function to cleanup test environment
cleanup_test_environment() {
    print_color $BLUE "Cleaning up test environment..."
    cd /tmp
    rm -rf "$TEST_DIR"
    print_color $GREEN "Cleanup complete"
}

# Function to test basic functionality
test_basic_functionality() {
    print_color $CYAN "Testing basic functionality..."
    
    # Test help
    run_test_command "Help command" "bwrapper — Generic bwrap sandboxing helper with configuration support" \
        ./bwrapper --help
    
    # Test list configurations
    run_test_command "List configurations" "Available configurations:" \
        ./bwrapper --list
    
    # Test dryrun with cursor config
    test_dryrun_output "Dryrun cursor config" \
        "bwrap" "--ro-bind" "/" "/" "--proc" "/proc" "--dev" "/dev" \
        ./bwrapper --dryrun cursor
}

# Function to test CLI argument handling
test_cli_arguments() {
    print_color $CYAN "Testing CLI argument handling..."
    
    # Test basic CLI execution
    test_dryrun_output "Basic CLI execution" \
        "bwrap" "--ro-bind" "/" "/" "--proc" "/proc" "--dev" "/dev" \
        ./bwrapper --exec /usr/bin/echo --dryrun hello world
    
    # Test CLI with arguments (your specific example)
    test_dryrun_output "CLI with find arguments" \
        "bwrap" "--ro-bind" "/" "/" "--proc" "/proc" "--dev" "/dev" \
        ./bwrapper --exec bash --arg find --arg . --dryrun path1 path2
    
    # Test CLI with read-write paths
    test_dryrun_output "CLI with read-write paths" \
        "bwrap" "--ro-bind" "/" "/" "--proc" "/proc" "--dev" "/dev" \
        ./bwrapper --exec /usr/bin/echo --rw /tmp/test --dryrun hello
    
    # Test CLI with environment variables
    test_dryrun_output "CLI with environment variables" \
        "bwrap" "--ro-bind" "/" "/" "--proc" "/proc" "--dev" "/dev" \
        ./bwrapper --exec /usr/bin/echo --env TEST_VAR=hello --dryrun test
}

# Function to test home isolation
test_home_isolation() {
    print_color $CYAN "Testing home isolation..."
    
    # Test home isolation without work directory
    test_dryrun_output "Home isolation without work" \
        "bwrap" "--ro-bind" "/" "/" "--tmpfs" "/home" "--bind" "test-home" "/home/app" "--setenv" "HOME" "/home/app" \
        ./bwrapper --exec /usr/bin/echo --home test-home --dryrun path1 path2
    
    # Test home isolation with work directory
    test_dryrun_output "Home isolation with work" \
        "bwrap" "--ro-bind" "/" "/" "--tmpfs" "/home" "--bind" "test-home" "/home/app" "--setenv" "HOME" "/home/app" \
        ./bwrapper --exec /usr/bin/echo --home test-home --work projects --dryrun path1 path2
    
    # Test home isolation environment variable
    test_dryrun_output "Home isolation environment" \
        "bwrap" "--ro-bind" "/" "/" "--tmpfs" "/home" "--setenv" "HOME" "/home/app" \
        ./bwrapper --exec /usr/bin/echo --home test-home --dryrun test
}

# Function to test configuration file mode
test_config_mode() {
    print_color $CYAN "Testing configuration file mode..."
    
    # Test cursor configuration
    test_dryrun_output "Cursor configuration" \
        "bwrap" "--ro-bind" "/" "/" "--proc" "/proc" "--dev" "/dev" \
        ./bwrapper --dryrun cursor
    
    # Test cursor configuration with files
    test_dryrun_output "Cursor configuration with files" \
        "bwrap" "--ro-bind" "/" "/" "--proc" "/proc" "--dev" "/dev" \
        ./bwrapper --dryrun cursor path1 path2
}

# Function to test error handling
test_error_handling() {
    print_color $CYAN "Testing error handling..."
    
    # Test missing configuration
    run_test_command "Missing configuration error" "Configuration file not found" \
        ./bwrapper --dryrun nonexistent_config
    
    # Test missing executable
    run_test_command "Missing executable error" "Error:" \
        ./bwrapper --exec /nonexistent/executable --dryrun test
    
    # Test invalid CLI options
    run_test_command "Invalid CLI options" "Error:" \
        ./bwrapper --arg test --dryrun test 2>/dev/null || true
}

# Function to test save configuration
test_save_configuration() {
    print_color $CYAN "Testing save configuration..."
    
    # Test saving CLI options as configuration
    run_test_command "Save CLI configuration" "Configuration saved to:" \
        ./bwrapper --exec /usr/bin/echo --arg test --rw /tmp/test --save test_config
    
    # Verify the saved configuration exists
    if [ -f "./configurations/test_config.conf" ]; then
        print_test_result "Saved configuration file exists" "PASS" ""
    else
        print_test_result "Saved configuration file exists" "FAIL" "Configuration file not created"
    fi
    
    # Test using saved configuration
    test_dryrun_output "Use saved configuration" \
        "bwrap" "--ro-bind" "/" "/" "--proc" "/proc" "--dev" "/dev" \
        ./bwrapper --dryrun test_config
    
    # Clean up test configuration
    rm -f "./configurations/test_config.conf"
}

# Function to test file mounting
test_file_mounting() {
    print_color $CYAN "Testing file mounting..."
    
    # Test mounting multiple files
    test_dryrun_output "Mount multiple files" \
        "bwrap" "--ro-bind" "/" "/" "--proc" "/proc" "--dev" "/dev" \
        ./bwrapper --exec /usr/bin/echo --dryrun path1/file1.txt path2/file2.txt path3/file3.txt
    
    # Test mounting directories
    test_dryrun_output "Mount directories" \
        "bwrap" "--ro-bind" "/" "/" "--proc" "/proc" "--dev" "/dev" \
        ./bwrapper --exec /usr/bin/echo --dryrun path1 path2 path3
}

# Function to run all tests
run_all_tests() {
    print_color $BLUE "Starting comprehensive bwrapper test suite..."
    print_color $YELLOW "Test directory: $TEST_DIR"
    echo
    
    setup_test_environment
    
    # Change to the bwrapper directory
    cd REPLACED_WITH_DYNAMIC_PATH/development/git/bwrap-cursor
    
    # Run all test categories
    test_basic_functionality
    test_cli_arguments
    test_home_isolation
    test_config_mode
    test_error_handling
    test_save_configuration
    test_file_mounting
    
    # Print final results
    echo
    print_color $BLUE "=== TEST RESULTS ==="
    print_color $GREEN "Passed: $PASSED"
    print_color $RED "Failed: $FAILED"
    print_color $YELLOW "Total:  $TOTAL"
    
    if [ $FAILED -eq 0 ]; then
        print_color $GREEN "🎉 All tests passed!"
        exit 0
    else
        print_color $RED "⚠️  Some tests failed!"
        exit 1
    fi
}

# Function to show help
show_help() {
    echo "test_bwrapper.sh — Comprehensive test suite for bwrapper"
    echo
    echo "Usage:"
    echo "  ./test_bwrapper.sh              # Run all tests"
    echo "  ./test_bwrapper.sh --verbose    # Run with verbose output"
    echo "  ./test_bwrapper.sh --help       # Show this help"
    echo
    echo "This script tests:"
    echo "  - Basic functionality (help, list, dryrun)"
    echo "  - CLI argument handling"
    echo "  - Home isolation features"
    echo "  - Configuration file mode"
    echo "  - Error handling"
    echo "  - Save configuration"
    echo "  - File mounting"
}

# Main execution
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                print_color $RED "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Set up cleanup trap
    trap cleanup_test_environment EXIT
    
    # Run tests
    run_all_tests
}

# Run main function
main "$@"

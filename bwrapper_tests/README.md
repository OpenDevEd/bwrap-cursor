# bwrapper Tests

This directory contains comprehensive tests for the bwrapper script.

## Test Files

- **`test_comprehensive.sh`** - Main comprehensive test suite with multiple options testing
- **`run_tests.sh`** - Test runner script (can be executed from project root)
- **`validate_bwrapper.sh`** - Manual validation script showing actual output
- **`test_automated.sh`** - Automated test with pattern matching
- **`simple_test.sh`** - Basic functionality tests
- **`test_bwrapper.sh`** - Complex comprehensive test suite
- **`test_bwrapper_simple.sh`** - Simplified comprehensive test

## Running Tests

### From the project root:
```bash
# Run all tests
./bwrapper_tests/run_tests.sh

# Run specific test
./bwrapper_tests/test_comprehensive.sh
```

### From the test directory:
```bash
cd bwrapper_tests
./test_comprehensive.sh
```

## Test Coverage

The comprehensive test suite covers:

### Basic Functionality
- Help command
- List configurations
- Basic dryrun

### Single Options
- Single `--arg`
- Single `--rw`
- Single `--env`

### Multiple Options (NEW)
- Multiple `--arg` options (find, grep, ls examples)
- Multiple `--rw` options (basic, cursor-like, development)
- Multiple `--env` options

### Combined Multiple Options
- Multiple `--arg` + `--rw`
- Multiple `--arg` + `--env`
- All multiple options together

### Home Isolation with Multiple Options
- Home isolation + multiple `--arg`
- Home isolation + multiple `--rw`
- Home isolation + work + multiple options

### Error Handling
- Missing configuration
- Invalid CLI options

### Configuration Management
- Save configuration with multiple options
- Use saved configuration

## Example Test Cases

### Multiple --arg Options
```bash
# Find command with multiple arguments
./bwrapper --exec bash --arg find --arg . --arg -name --arg "*.txt" --dryrun /tmp

# Grep command with multiple arguments
./bwrapper --exec grep --arg -r --arg -n --arg pattern --dryrun file1 file2

# LS command with multiple arguments
./bwrapper --exec ls --arg -la --arg -h --arg --color=auto --dryrun /tmp
```

### Multiple --rw Options
```bash
# Basic multiple read-write paths
./bwrapper --exec /usr/bin/echo --rw /tmp/test1 --rw /tmp/test2 --dryrun hello

# Cursor-like multiple paths
./bwrapper --exec /usr/bin/echo --rw /tmp/.config --rw /tmp/.cache --rw /tmp/.local --dryrun test

# Development multiple paths
./bwrapper --exec /usr/bin/echo --rw /tmp/project1 --rw /tmp/project2 --rw /tmp/project3 --dryrun build
```

### Combined Multiple Options
```bash
# Multiple --arg + --rw
./bwrapper --exec bash --arg find --arg . --arg -name --arg "*.txt" --rw /tmp/output --rw /tmp/logs --dryrun /tmp

# All multiple options
./bwrapper --exec bash --arg find --arg . --arg -type --arg f --rw /tmp/results --rw /tmp/temp --env SEARCH_PATH=/tmp --env OUTPUT_FORMAT=json --dryrun /tmp
```

## Test Results

All tests validate that:
- Multiple `--arg` options are properly collected and passed to the executable
- Multiple `--rw` options are properly bound as read-write paths
- Multiple `--env` options are properly set as environment variables
- Combined multiple options work correctly together
- Home isolation works with multiple options
- Configuration saving/loading works with multiple options
- Error handling works correctly

## Requirements

- bash
- bwrapper script (must be executable)
- bwrap (bubblewrap) - for actual execution (not required for dryrun tests)

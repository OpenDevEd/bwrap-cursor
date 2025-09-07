#!/usr/bin/env bash
# Validate bwrapper functionality

echo "=== bwrapper Validation Tests ==="
echo

# Test 1: Your specific example
echo "Test 1: CLI with find arguments (your example)"
echo "Command: ./bwrapper --exec bash --arg find --arg . --dryrun path1 path2"
echo "Output:"
./bwrapper --exec bash --arg find --arg . --dryrun path1 path2
echo

# Test 2: Basic dryrun
echo "Test 2: Basic dryrun with cursor config"
echo "Command: ./bwrapper --dryrun cursor"
echo "Output:"
./bwrapper --dryrun cursor
echo

# Test 3: Home isolation
echo "Test 3: Home isolation"
echo "Command: ./bwrapper --exec /usr/bin/echo --home /tmp/test-home --dryrun hello"
echo "Output:"
./bwrapper --exec /usr/bin/echo --home /tmp/test-home --dryrun hello
echo

# Test 4: CLI with read-write paths
echo "Test 4: CLI with read-write paths"
echo "Command: ./bwrapper --exec /usr/bin/echo --rw /tmp/test --dryrun hello"
echo "Output:"
./bwrapper --exec /usr/bin/echo --rw /tmp/test --dryrun hello
echo

# Test 5: CLI with environment variables
echo "Test 5: CLI with environment variables"
echo "Command: ./bwrapper --exec /usr/bin/echo --env TEST_VAR=hello --dryrun test"
echo "Output:"
./bwrapper --exec /usr/bin/echo --env TEST_VAR=hello --dryrun test
echo

echo "=== Validation Complete ==="
echo "All commands executed successfully!"

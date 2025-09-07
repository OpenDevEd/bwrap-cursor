#!/usr/bin/env bash
# Simple test for bwrapper

set -euo pipefail

echo "Testing bwrapper functionality..."

# Test 1: Help command
echo "Test 1: Help command"
if ./bwrapper --help | grep -q "bwrapper — Generic bwrap sandboxing helper with configuration support"; then
    echo "✅ Help command: PASS"
else
    echo "❌ Help command: FAIL"
fi

# Test 2: Your specific example
echo "Test 2: CLI with find arguments"
if ./bwrapper --exec bash --arg find --arg . --dryrun path1 path2 | grep -q "bwrap"; then
    echo "✅ CLI with find arguments: PASS"
else
    echo "❌ CLI with find arguments: FAIL"
fi

# Test 3: Basic dryrun
echo "Test 3: Basic dryrun"
if ./bwrapper --dryrun cursor | grep -q "bwrap"; then
    echo "✅ Basic dryrun: PASS"
else
    echo "❌ Basic dryrun: FAIL"
fi

# Test 4: Home isolation
echo "Test 4: Home isolation"
if ./bwrapper --exec /usr/bin/echo --home /tmp/test-home --dryrun hello | grep -q "tmpfs" && ./bwrapper --exec /usr/bin/echo --home /tmp/test-home --dryrun hello | grep -q "/home"; then
    echo "✅ Home isolation: PASS"
else
    echo "❌ Home isolation: FAIL"
fi

echo "Tests completed!"

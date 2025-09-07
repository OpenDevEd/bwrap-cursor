#!/usr/bin/env bash
# Simple test for debugging

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BWRAPPER="$PROJECT_ROOT/bwrapper"

echo "Testing from: $SCRIPT_DIR"
echo "Project root: $PROJECT_ROOT"
echo "bwrapper path: $BWRAPPER"
echo

# Test 1: Help command
echo "Test 1: Help command"
if "$BWRAPPER" --help | grep -q "bwrapper — Generic bwrap sandboxing helper with configuration support"; then
    echo -e "${GREEN}✅ Help command: PASS${NC}"
else
    echo -e "${RED}❌ Help command: FAIL${NC}"
fi

# Test 2: Multiple --arg
echo "Test 2: Multiple --arg"
if "$BWRAPPER" --exec bash --arg find --arg . --dryrun path1 path2 | grep -q "bwrap"; then
    echo -e "${GREEN}✅ Multiple --arg: PASS${NC}"
else
    echo -e "${RED}❌ Multiple --arg: FAIL${NC}"
fi

# Test 3: Multiple --rw
echo "Test 3: Multiple --rw"
if "$BWRAPPER" --exec /usr/bin/echo --rw /tmp/test1 --rw /tmp/test2 --dryrun hello | grep -q "bwrap"; then
    echo -e "${GREEN}✅ Multiple --rw: PASS${NC}"
else
    echo -e "${RED}❌ Multiple --rw: FAIL${NC}"
fi

echo "Tests completed!"

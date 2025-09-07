#!/usr/bin/env bash
# Test runner for bwrapper tests

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${CYAN}=== bwrapper Test Runner ===${NC}"
echo -e "${BLUE}Project root: $PROJECT_ROOT${NC}"
echo -e "${BLUE}Test directory: $SCRIPT_DIR${NC}"
echo

# Change to project root
cd "$PROJECT_ROOT"

# Make sure bwrapper is executable
if [ ! -x "./bwrapper" ]; then
    echo -e "${RED}Error: bwrapper is not executable${NC}"
    exit 1
fi

# Run comprehensive tests
echo -e "${BLUE}Running comprehensive tests...${NC}"
if "$SCRIPT_DIR/test_comprehensive.sh"; then
    echo -e "${GREEN}✅ Comprehensive tests passed!${NC}"
else
    echo -e "${RED}❌ Comprehensive tests failed!${NC}"
    exit 1
fi

echo
echo -e "${GREEN}🎉 All tests completed successfully!${NC}"

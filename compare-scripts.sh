#!/usr/bin/env bash
# compare-scripts.sh — Compare bcursor.sh and bwrapper dryrun outputs
# Usage:
#   ./compare-scripts.sh [arguments...]  # Compare with optional arguments

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to run dryrun and capture output
run_dryrun() {
    local script=$1
    local args=("${@:2}")
    
    if [ ${#args[@]} -eq 0 ]; then
        "$script" --dryrun 2>&1
    else
        "$script" --dryrun "${args[@]}" 2>&1
    fi
}

# Function to normalize output for comparison
normalize_output() {
    # Remove trailing backslashes and normalize whitespace
    sed 's/\\$//' | \
    sed 's/^[[:space:]]*//' | \
    sed 's/[[:space:]]*$//' | \
    sort
}

# Main comparison function
compare_scripts() {
    local args=("$@")
    local bcursor_output
    local helper_output
    local bcursor_normalized
    local helper_normalized
    
    print_color $BLUE "Comparing bcursor.sh and bwrapper dryrun outputs..."
    echo
    
    if [ ${#args[@]} -gt 0 ]; then
        print_color $YELLOW "Arguments: ${args[*]}"
        echo
    fi
    
    # Run both scripts and capture output
    print_color $BLUE "Running bcursor.sh --dryrun..."
    bcursor_output=$(run_dryrun "./bcursor.sh" "${args[@]}")
    
    print_color $BLUE "Running bwrapper --dryrun cursor..."
    helper_output=$(run_dryrun "./bwrapper" "cursor" "${args[@]}")
    
    # Normalize outputs for comparison
    bcursor_normalized=$(echo "$bcursor_output" | normalize_output)
    helper_normalized=$(echo "$helper_output" | normalize_output)
    
    echo
    print_color $BLUE "=== COMPARISON RESULTS ==="
    echo
    
    # Check if outputs are identical
    if diff -q <(echo "$bcursor_normalized") <(echo "$helper_normalized") >/dev/null 2>&1; then
        print_color $GREEN "✅ PASS: Both scripts produce identical bwrap commands!"
        echo
        print_color $GREEN "The commands are functionally equivalent."
    else
        print_color $RED "❌ FAIL: Scripts produce different bwrap commands"
        echo
        print_color $YELLOW "=== DIFFERENCES ==="
        echo
        diff -u <(echo "$bcursor_normalized") <(echo "$helper_normalized") || true
        echo
        print_color $YELLOW "=== RAW OUTPUTS ==="
        echo
        print_color $BLUE "bcursor.sh output:"
        echo "$bcursor_output"
        echo
        print_color $BLUE "bwrapper output:"
        echo "$helper_output"
    fi
    
    echo
    print_color $BLUE "=== DETAILED ANALYSIS ==="
    echo
    
    # Count arguments
    local bcursor_args=$(echo "$bcursor_output" | grep -c '^[[:space:]]*"[^"]*"[[:space:]]*\\$' || echo "0")
    local helper_args=$(echo "$helper_output" | grep -c '^[[:space:]]*"[^"]*"[[:space:]]*\\$' || echo "0")
    
    print_color $YELLOW "bcursor.sh bwrap arguments: $bcursor_args"
    print_color $YELLOW "bwrapper bwrap arguments: $helper_args"
    
    # Check for specific differences
    local differences=0
    
    # Check for key components
    local checks=(
        "ro-bind:Read-only filesystem binding"
        "Cursor:Cursor directory bindings"
        "DISPLAY:DISPLAY environment variable"
        "XDG_RUNTIME_DIR:XDG_RUNTIME_DIR environment variable"
        "DBUS_SESSION_BUS_ADDRESS:DBUS environment variable"
        "proc:Process filesystem"
        "dev:Device filesystem"
        "tmpfs:Temporary filesystem"
    )
    
    for check in "${checks[@]}"; do
        local pattern="${check%%:*}"
        local description="${check#*:}"
        
        if echo "$bcursor_output" | grep -q "$pattern" && echo "$helper_output" | grep -q "$pattern"; then
            print_color $GREEN "✅ Both have $description"
        else
            print_color $RED "❌ $description differs"
            ((differences++))
        fi
    done
    
    echo
    if [ $differences -eq 0 ]; then
        print_color $GREEN "🎉 All checks passed! The scripts are functionally equivalent."
    else
        print_color $RED "⚠️  Found $differences differences between the scripts."
    fi
}

# Show usage if help requested
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "compare-scripts.sh — Compare bcursor.sh and bwrapper dryrun outputs"
    echo
    echo "Usage:"
    echo "  ./compare-scripts.sh                    # Compare with no arguments"
    echo "  ./compare-scripts.sh file1 file2        # Compare with specific files"
    echo "  ./compare-scripts.sh --help             # Show this help"
    echo
    echo "This script runs both bcursor.sh --dryrun and bwrapper --dryrun cursor"
    echo "with the same arguments and compares their outputs to verify they produce"
    echo "functionally equivalent bwrap commands."
    exit 0
fi

# Run the comparison
compare_scripts "$@"

#!/bin/bash
# Run Perl tests with optional filtering and debug mode
#
# Usage:
#   ./run-tests.sh                    # Run all tests
#   ./run-tests.sh t/01_*.t          # Run specific test file(s)
#   FILTER=foo ./run-tests.sh        # Run tests with subtest filtering
#   DEBUG=1 FILTER=foo ./run-tests.sh # Run with debug mode

set -e

# Set SUBTEST_FILTER from FILTER env var if provided
if [ -n "$FILTER" ]; then
    export SUBTEST_FILTER="$FILTER"
fi

# Set SUBTEST_FILTER_DEBUG from DEBUG env var if provided
if [ -n "$DEBUG" ]; then
    export SUBTEST_FILTER_DEBUG=1
fi

# Default to all tests if no arguments provided
if [ $# -eq 0 ]; then
    set -- t/
fi

# Show environment variables if set
if [ -n "$SUBTEST_FILTER" ]; then
    echo "SUBTEST_FILTER=$SUBTEST_FILTER"
fi
if [ -n "$SUBTEST_FILTER_DEBUG" ]; then
    echo "SUBTEST_FILTER_DEBUG=$SUBTEST_FILTER_DEBUG"
fi

# Run tests
exec prove -lv "$@"

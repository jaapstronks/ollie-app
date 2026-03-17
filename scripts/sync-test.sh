#!/bin/bash
#
# sync-test.sh - Ollie CloudKit Sync Log Capture Tool
#
# Captures and filters CloudKit sync logs from the iOS Simulator.
# Logs are saved to ~/Desktop/OllieSyncLogs/ with timestamps.
#
# Usage:
#   ./scripts/sync-test.sh              # All sync logs
#   ./scripts/sync-test.sh -r AA000000  # Logs for test records only
#   ./scripts/sync-test.sh -p SEND      # Logs for SEND phase only
#   ./scripts/sync-test.sh -c SyncCoordinator  # Logs for specific category
#   ./scripts/sync-test.sh -t           # Test records only (shortcut)
#
# Options:
#   -r <id>      Filter by record ID (partial match)
#   -p <phase>   Filter by sync phase (QUEUE, SEND, SENT, RECV, APPLY, CONFLICT, ERROR, DELETE, PHOTO)
#   -c <cat>     Filter by category (SyncCoordinator, SyncEngine-private, SyncEngine-shared)
#   -t           Test records only (records starting with AA000000)
#   -o <file>    Custom output filename (default: auto-generated with timestamp)
#   -l <level>   Log level: debug, info, error (default: debug)
#   -n           No file output - stream to terminal only
#   -h           Show this help
#

set -e

SUBSYSTEM="nl.jaapstronks.Otis"
LOG_DIR="$HOME/Desktop/OllieSyncLogs"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE=""
LEVEL="debug"
FILTER=""
NO_FILE=false

# Parse arguments
while getopts "r:p:c:to:l:nh" opt; do
    case $opt in
        r)
            FILTER="$FILTER AND message CONTAINS \"[$OPTARG\""
            ;;
        p)
            FILTER="$FILTER AND message CONTAINS \"[$OPTARG]\""
            ;;
        c)
            FILTER="$FILTER AND category==\"$OPTARG\""
            ;;
        t)
            FILTER="$FILTER AND message CONTAINS \"[AA000000]\""
            ;;
        o)
            LOG_FILE="$OPTARG"
            ;;
        l)
            LEVEL="$OPTARG"
            ;;
        n)
            NO_FILE=true
            ;;
        h)
            head -35 "$0" | tail -30
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# Build predicate
PREDICATE="subsystem==\"$SUBSYSTEM\"$FILTER"

# Determine output file
if [ -z "$LOG_FILE" ] && [ "$NO_FILE" = false ]; then
    mkdir -p "$LOG_DIR"
    LOG_FILE="$LOG_DIR/sync-$TIMESTAMP.log"
fi

# Print header
echo ""
echo "=========================================="
echo "  Ollie CloudKit Sync Log Capture"
echo "=========================================="
echo ""
echo "Predicate: $PREDICATE"
echo "Level: $LEVEL"
if [ "$NO_FILE" = false ]; then
    echo "Output: $LOG_FILE"
fi
echo ""
echo "Press Ctrl+C to stop"
echo ""
echo "--- Live logs ---"
echo ""

# Stream logs
if [ "$NO_FILE" = true ]; then
    xcrun simctl spawn booted log stream \
        --predicate "$PREDICATE" \
        --level "$LEVEL" \
        --style compact
else
    xcrun simctl spawn booted log stream \
        --predicate "$PREDICATE" \
        --level "$LEVEL" \
        --style compact \
        | tee "$LOG_FILE"
fi

# Cleanup message
if [ "$NO_FILE" = false ]; then
    echo ""
    echo "Logs saved to: $LOG_FILE"
fi

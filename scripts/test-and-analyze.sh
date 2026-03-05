#!/bin/bash
# Otis App - Test and Prepare for Analysis
# Runs UI tests and prepares output for Claude Code analysis

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
REPORTS_DIR="$PROJECT_ROOT/.maestro/reports"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Otis App - Test & Prepare for Analysis            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Parse optional target device from args
TARGET_DEVICE=""
for ((i=1; i<=$#; i++)); do
    if [ "${!i}" = "-d" ] || [ "${!i}" = "--device" ]; then
        next_index=$((i + 1))
        TARGET_DEVICE="${!next_index}"
        break
    fi
done

# Check for booted simulator
if [ -n "$TARGET_DEVICE" ]; then
    BOOTED_SIM=$(xcrun simctl list devices booted 2>/dev/null | grep "$TARGET_DEVICE" | head -1 || true)
else
    BOOTED_SIM=$(xcrun simctl list devices booted 2>/dev/null | grep -E "iPhone|iPad" | head -1 || true)
fi
if [ -z "$BOOTED_SIM" ]; then
    if [ -n "$TARGET_DEVICE" ]; then
        echo -e "${YELLOW}Target simulator is not booted:${NC} $TARGET_DEVICE"
    else
        echo -e "${YELLOW}No simulator is currently booted.${NC}"
    fi
    echo ""
    echo "To boot a simulator, run:"
    echo "  xcrun simctl boot '${TARGET_DEVICE:-iPhone 17 Pro}'"
    echo "  open -a Simulator"
    echo ""
    echo "Or open Xcode and run the app (Cmd+R), which will boot a simulator."
    exit 1
fi

echo -e "${GREEN}Simulator detected:${NC} $BOOTED_SIM"
echo ""

# Check if app is installed
APP_INSTALLED=$(xcrun simctl listapps booted 2>/dev/null | grep "jaapstronks.Otis-app" || true)
if [ -z "$APP_INSTALLED" ]; then
    echo -e "${YELLOW}App not installed on simulator.${NC}"
    echo ""
    echo "Please build and run the app from Xcode first (Cmd+R)."
    exit 1
fi

echo -e "${GREEN}App is installed.${NC}"
echo ""

# Run the tests
echo -e "${BLUE}Running UI tests...${NC}"
"$SCRIPT_DIR/run-ui-tests.sh" "$@"

# Show analysis instructions
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Tests complete! Ready for analysis.${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}To have Claude analyze the results, copy and paste this:${NC}"
echo ""
echo "────────────────────────────────────────────────────────────"
echo "Please analyze the UI test results:"
echo ""
echo "1. Read the test report at .maestro/reports/latest/test-report.md"
echo "2. Review each screenshot in the report"
echo "3. Identify any visual issues, UX problems, or bugs"
echo "4. Suggest specific improvements with code changes"
echo "────────────────────────────────────────────────────────────"
echo ""
echo -e "${YELLOW}Screenshot files to review:${NC}"
ls -1 "$REPORTS_DIR/latest"/*.png 2>/dev/null | head -10 || echo "  (no screenshots found)"
echo ""

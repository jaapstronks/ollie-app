#!/bin/bash
# Ollie App - UI Test Runner
# Generates Claude-parseable test reports with screenshots

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MAESTRO_DIR="$PROJECT_ROOT/.maestro"
REPORTS_DIR="$PROJECT_ROOT/.maestro/reports"
SCREENSHOTS_DIR="$PROJECT_ROOT/.maestro/screenshots"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_DIR="$REPORTS_DIR/$TIMESTAMP"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
FLOW_NAME=""
SCENARIO=""
INSTRUCTIONS=""
VERBOSE=false

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -f, --flow <name>       Run a specific flow (e.g., 'complete-user-journey')"
    echo "  -s, --scenario <file>   Run a scenario file from .maestro/scenarios/"
    echo "  -a, --all               Run the full test suite"
    echo "  -i, --instructions <text>  Custom instructions to include in report"
    echo "  -v, --verbose           Show Maestro output in real-time"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -a                              # Run full test suite"
    echo "  $0 -f complete-user-journey        # Run specific flow"
    echo "  $0 -s poop-tracker-test            # Run scenario"
    echo "  $0 -a -i 'Test the new poop warning feature'"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--flow)
            FLOW_NAME="$2"
            shift 2
            ;;
        -s|--scenario)
            SCENARIO="$2"
            shift 2
            ;;
        -a|--all)
            FLOW_NAME="full-test-suite"
            shift
            ;;
        -i|--instructions)
            INSTRUCTIONS="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Validate arguments
if [ -z "$FLOW_NAME" ] && [ -z "$SCENARIO" ]; then
    echo -e "${RED}Error: Must specify a flow (-f), scenario (-s), or all (-a)${NC}"
    print_usage
    exit 1
fi

# Create directories
mkdir -p "$REPORT_DIR"
mkdir -p "$SCREENSHOTS_DIR"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Ollie App - UI Test Runner                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Timestamp:${NC} $TIMESTAMP"
echo -e "${YELLOW}Report directory:${NC} $REPORT_DIR"
echo ""

# Determine what to run
if [ -n "$SCENARIO" ]; then
    FLOW_FILE="$MAESTRO_DIR/scenarios/$SCENARIO.yaml"
    if [ ! -f "$FLOW_FILE" ]; then
        echo -e "${RED}Error: Scenario file not found: $FLOW_FILE${NC}"
        exit 1
    fi
    echo -e "${YELLOW}Running scenario:${NC} $SCENARIO"
else
    FLOW_FILE="$MAESTRO_DIR/flows/$FLOW_NAME.yaml"
    if [ ! -f "$FLOW_FILE" ]; then
        echo -e "${RED}Error: Flow file not found: $FLOW_FILE${NC}"
        exit 1
    fi
    echo -e "${YELLOW}Running flow:${NC} $FLOW_NAME"
fi

# Copy current screenshots dir to report (for before state)
if [ -d "$SCREENSHOTS_DIR" ] && [ "$(ls -A $SCREENSHOTS_DIR 2>/dev/null)" ]; then
    cp -r "$SCREENSHOTS_DIR" "$REPORT_DIR/screenshots_before"
fi

# Clear screenshots for fresh run
rm -rf "$SCREENSHOTS_DIR"/*

echo ""
echo -e "${BLUE}Starting Maestro test run...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Run Maestro and capture output
MAESTRO_OUTPUT_FILE="$REPORT_DIR/maestro_output.txt"
MAESTRO_EXIT_CODE=0
START_TIME=$(date +%s)

cd "$PROJECT_ROOT"

if [ "$VERBOSE" = true ]; then
    # Show output in real-time and capture it
    maestro test "$FLOW_FILE" --format junit --output "$REPORT_DIR/junit.xml" 2>&1 | tee "$MAESTRO_OUTPUT_FILE" || MAESTRO_EXIT_CODE=$?
else
    # Capture output silently
    maestro test "$FLOW_FILE" --format junit --output "$REPORT_DIR/junit.xml" > "$MAESTRO_OUTPUT_FILE" 2>&1 || MAESTRO_EXIT_CODE=$?
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Move screenshots to report directory
if [ -d "$SCREENSHOTS_DIR" ] && [ "$(ls -A $SCREENSHOTS_DIR 2>/dev/null)" ]; then
    mv "$SCREENSHOTS_DIR"/* "$REPORT_DIR/" 2>/dev/null || true
fi

# Also check for screenshots in .maestro/screenshots (Maestro's default)
if [ -d "$MAESTRO_DIR/screenshots" ] && [ "$(ls -A $MAESTRO_DIR/screenshots 2>/dev/null)" ]; then
    cp -r "$MAESTRO_DIR/screenshots"/* "$REPORT_DIR/" 2>/dev/null || true
fi

# Determine test status
if [ $MAESTRO_EXIT_CODE -eq 0 ]; then
    TEST_STATUS="PASSED"
    STATUS_COLOR=$GREEN
else
    TEST_STATUS="FAILED"
    STATUS_COLOR=$RED
fi

echo ""
echo -e "${STATUS_COLOR}Test Status: $TEST_STATUS${NC}"
echo -e "${YELLOW}Duration:${NC} ${DURATION}s"

# Generate the Claude-parseable report
REPORT_FILE="$REPORT_DIR/test-report.md"

cat > "$REPORT_FILE" << EOF
# UI Test Report

## Summary
- **Timestamp:** $TIMESTAMP
- **Flow/Scenario:** ${SCENARIO:-$FLOW_NAME}
- **Status:** $TEST_STATUS
- **Duration:** ${DURATION}s
- **Report Directory:** $REPORT_DIR

EOF

# Add test instructions if provided
if [ -n "$INSTRUCTIONS" ]; then
    cat >> "$REPORT_FILE" << EOF
## Test Instructions
$INSTRUCTIONS

EOF
fi

# Add screenshots section
cat >> "$REPORT_FILE" << EOF
## Screenshots

The following screenshots were captured during the test run:

EOF

# List all screenshots
SCREENSHOT_COUNT=0
for screenshot in "$REPORT_DIR"/*.png "$REPORT_DIR"/**/*.png 2>/dev/null; do
    if [ -f "$screenshot" ]; then
        SCREENSHOT_NAME=$(basename "$screenshot")
        SCREENSHOT_REL_PATH="${screenshot#$PROJECT_ROOT/}"
        echo "- \`$SCREENSHOT_REL_PATH\`" >> "$REPORT_FILE"
        SCREENSHOT_COUNT=$((SCREENSHOT_COUNT + 1))
    fi
done

if [ $SCREENSHOT_COUNT -eq 0 ]; then
    echo "_No screenshots captured_" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"

# Add Maestro output
cat >> "$REPORT_FILE" << EOF
## Maestro Output

\`\`\`
$(cat "$MAESTRO_OUTPUT_FILE" | head -200)
\`\`\`

EOF

# Add JUnit results if available
if [ -f "$REPORT_DIR/junit.xml" ]; then
    cat >> "$REPORT_FILE" << EOF
## JUnit Results

\`\`\`xml
$(cat "$REPORT_DIR/junit.xml")
\`\`\`

EOF
fi

# Add analysis section for Claude
cat >> "$REPORT_FILE" << EOF
## For Claude Analysis

### What to check:
1. Review the screenshots for visual issues
2. Check if all test steps passed
3. Look for any error messages in the output
4. Verify the UI elements are positioned correctly
5. Check for any accessibility issues visible in screenshots

### File paths for screenshot review:
EOF

for screenshot in "$REPORT_DIR"/*.png "$REPORT_DIR"/**/*.png 2>/dev/null; do
    if [ -f "$screenshot" ]; then
        echo "- $screenshot" >> "$REPORT_FILE"
    fi
done

# Create latest symlink
rm -f "$REPORTS_DIR/latest"
ln -s "$REPORT_DIR" "$REPORTS_DIR/latest"

echo ""
echo -e "${GREEN}Report generated:${NC} $REPORT_FILE"
echo -e "${GREEN}Latest symlink:${NC} $REPORTS_DIR/latest/test-report.md"
echo ""
echo -e "${BLUE}To view the report:${NC}"
echo "  cat $REPORT_FILE"
echo ""
echo -e "${BLUE}To have Claude analyze the results:${NC}"
echo "  # In Claude Code, say:"
echo "  'Read the test report at .maestro/reports/latest/test-report.md and analyze the screenshots'"
echo ""

exit $MAESTRO_EXIT_CODE

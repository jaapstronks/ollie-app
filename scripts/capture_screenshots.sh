#!/bin/bash
#
# Screenshot capture script for Ollie app
# Captures App Store screenshots in all supported languages
#
# Usage:
#   ./scripts/capture_screenshots.sh              # All languages, iPhone 16 Pro
#   ./scripts/capture_screenshots.sh en           # Single language
#   ./scripts/capture_screenshots.sh nl "iPhone SE (3rd generation)"  # Single language + device
#

set -e

# Configuration
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$PROJECT_DIR/Ollie-app.xcodeproj"
SCHEME="Ollie-app"
OUTPUT_DIR="$PROJECT_DIR/fastlane/screenshots"

# Languages (locale codes)
ALL_LANGUAGES=("en-US" "nl-NL" "de-DE" "es-ES" "fr-FR" "it-IT" "sv-SE")

# Default device
DEFAULT_DEVICE="iPhone 16 Pro"

# Parse arguments
LANG="${1:-all}"
DEVICE="${2:-$DEFAULT_DEVICE}"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "=== Ollie App Screenshot Capture ==="
echo "Output: $OUTPUT_DIR"
echo "Device: $DEVICE"
echo ""

capture_for_language() {
    local lang="$1"
    local device="$2"

    echo "📸 Capturing screenshots for: $lang on $device"

    # Extract language code (e.g., "en" from "en-US")
    local lang_code="${lang%%-*}"

    # Create language-specific output folder
    local lang_output="$OUTPUT_DIR/$lang"
    mkdir -p "$lang_output"

    # Run UI tests with language override
    xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,name=$device" \
        -only-testing:Ollie-appUITests/ScreenshotTests/testCaptureAllScreenshots \
        -testLanguage "$lang_code" \
        -testRegion "${lang#*-}" \
        SIMULATOR_LANGUAGE="$lang" \
        SIMULATOR_LOCALE="$lang" \
        SIMULATOR_DEVICE_NAME="$device" \
        -resultBundlePath "$lang_output/TestResults.xcresult" \
        2>&1 | tee "$lang_output/build.log" || true

    # Extract screenshots from test results
    if [ -d "$lang_output/TestResults.xcresult" ]; then
        echo "  Extracting screenshots..."
        xcrun xcresulttool get --path "$lang_output/TestResults.xcresult" \
            --format json > "$lang_output/results.json" 2>/dev/null || true

        # Copy screenshots from temp directory if they exist
        find /tmp -name "*${lang}*.png" -newer "$lang_output" 2>/dev/null | while read f; do
            cp "$f" "$lang_output/" 2>/dev/null || true
        done
    fi

    echo "  ✅ Done: $lang"
    echo ""
}

# Main execution
if [ "$LANG" = "all" ]; then
    echo "Capturing all ${#ALL_LANGUAGES[@]} languages..."
    echo ""
    for lang in "${ALL_LANGUAGES[@]}"; do
        capture_for_language "$lang" "$DEVICE"
    done
else
    # Single language mode
    # Convert short code to full locale if needed
    case "$LANG" in
        en) LANG="en-US" ;;
        nl) LANG="nl-NL" ;;
        de) LANG="de-DE" ;;
        es) LANG="es-ES" ;;
        fr) LANG="fr-FR" ;;
        it) LANG="it-IT" ;;
        sv) LANG="sv-SE" ;;
    esac
    capture_for_language "$LANG" "$DEVICE"
fi

echo "=== Screenshot capture complete ==="
echo "Screenshots saved to: $OUTPUT_DIR"
echo ""
echo "To view results:"
echo "  open $OUTPUT_DIR"

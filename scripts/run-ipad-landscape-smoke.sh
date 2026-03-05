#!/bin/bash
# iPad landscape smoke lane for Maestro flows

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_DEVICE="iPad Pro 11-inch (M4)"
DEVICE="${1:-$DEFAULT_DEVICE}"

# Best-effort orientation switch for booted simulator.
# If unavailable on host Xcode tools, tests still run.
if xcrun simctl list devices booted | rg -q "$DEVICE"; then
  xcrun simctl ui booted orientation landscapeRight >/dev/null 2>&1 || true
fi

"$SCRIPT_DIR/run-ui-tests.sh" \
  -f complete-user-journey \
  -d "$DEVICE" \
  -i "iPad landscape smoke lane"

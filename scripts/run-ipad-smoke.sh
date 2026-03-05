#!/bin/bash
# iPad portrait smoke lane for Maestro flows

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_DEVICE="iPad Pro 11-inch (M4)"
DEVICE="${1:-$DEFAULT_DEVICE}"

"$SCRIPT_DIR/run-ui-tests.sh" \
  -f complete-user-journey \
  -d "$DEVICE" \
  -i "iPad portrait smoke lane"

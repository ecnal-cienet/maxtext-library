#!/bin/bash

# MaxText Documentation Update Script
# Manually trigger documentation updates for changed files after git pull
#
# Usage:
#   ./scripts/update-docs-from-pull.sh              # Check for updates needed
#   ./scripts/update-docs-from-pull.sh --auto       # Auto-update docs (requires Claude Code)

set -e

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
HELPER_SCRIPT="$REPO_ROOT/.git/hooks/update-docs-helper.py"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}MaxText Documentation Update Tool${NC}"
echo "===================================="
echo ""

# Check if helper script exists
if [ ! -f "$HELPER_SCRIPT" ]; then
    echo -e "${RED}Error: Helper script not found at $HELPER_SCRIPT${NC}"
    exit 1
fi

# Run the helper to detect changes
python3 "$HELPER_SCRIPT" "$REPO_ROOT"

# Check if there's a docs-to-update file
if [ -f "$REPO_ROOT/.git/docs-to-update.txt" ]; then
    echo -e "${GREEN}✓ Documentation update list saved to .git/docs-to-update.txt${NC}"
    echo ""

    if [ "$1" == "--auto" ]; then
        echo -e "${YELLOW}Auto-update mode not yet implemented${NC}"
        echo "Please manually request documentation updates using Claude Code"
    fi
fi

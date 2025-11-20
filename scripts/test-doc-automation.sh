#!/bin/bash

# MaxText Documentation Auto-Update - Test Script
# This script simulates what happens during a git merge to test the automation

set -e

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

echo "Testing documentation automation system..."
echo ""

# Run the helper script
python3 "$REPO_ROOT/.git/hooks/update-docs-helper.py" "$REPO_ROOT"

echo ""
echo "Test complete!"

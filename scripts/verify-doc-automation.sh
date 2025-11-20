#!/bin/bash

# MaxText Documentation Automation Verification Script
# Checks if the post-merge documentation automation is properly installed

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}MaxText Documentation Automation Verification${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check 1: Post-merge hook exists
echo -e "${CYAN}✓ Checking post-merge hook...${NC}"
if [ -f "$REPO_ROOT/.git/hooks/post-merge" ]; then
    echo -e "${GREEN}  ✓ Hook file exists${NC}"

    if [ -x "$REPO_ROOT/.git/hooks/post-merge" ]; then
        echo -e "${GREEN}  ✓ Hook is executable${NC}"
    else
        echo -e "${YELLOW}  ⚠ Hook exists but is not executable${NC}"
        echo -e "    Run: chmod +x $REPO_ROOT/.git/hooks/post-merge"
    fi
else
    echo -e "${RED}  ✗ Hook file not found${NC}"
    echo -e "    Expected: $REPO_ROOT/.git/hooks/post-merge"
fi
echo ""

# Check 2: Helper script exists
echo -e "${CYAN}✓ Checking helper script...${NC}"
if [ -f "$REPO_ROOT/.git/hooks/update-docs-helper.py" ]; then
    echo -e "${GREEN}  ✓ Helper script exists${NC}"

    if [ -x "$REPO_ROOT/.git/hooks/update-docs-helper.py" ]; then
        echo -e "${GREEN}  ✓ Helper script is executable${NC}"
    else
        echo -e "${YELLOW}  ⚠ Helper script exists but is not executable${NC}"
        echo -e "    Run: chmod +x $REPO_ROOT/.git/hooks/update-docs-helper.py"
    fi
else
    echo -e "${RED}  ✗ Helper script not found${NC}"
    echo -e "    Expected: $REPO_ROOT/.git/hooks/update-docs-helper.py"
fi
echo ""

# Check 3: Manual trigger script exists
echo -e "${CYAN}✓ Checking manual trigger script...${NC}"
if [ -f "$REPO_ROOT/scripts/update-docs-from-pull.sh" ]; then
    echo -e "${GREEN}  ✓ Trigger script exists${NC}"

    if [ -x "$REPO_ROOT/scripts/update-docs-from-pull.sh" ]; then
        echo -e "${GREEN}  ✓ Trigger script is executable${NC}"
    else
        echo -e "${YELLOW}  ⚠ Trigger script exists but is not executable${NC}"
        echo -e "    Run: chmod +x $REPO_ROOT/scripts/update-docs-from-pull.sh"
    fi
else
    echo -e "${YELLOW}  ⚠ Manual trigger script not found (optional)${NC}"
    echo -e "    Expected: $REPO_ROOT/scripts/update-docs-from-pull.sh"
fi
echo ""

# Check 4: Documentation files exist
echo -e "${CYAN}✓ Checking documentation files...${NC}"
if [ -f "$REPO_ROOT/CLAUDE.md" ]; then
    echo -e "${GREEN}  ✓ CLAUDE.md exists${NC}"

    if grep -q "Automated Documentation Updates with Post-Merge Hook" "$REPO_ROOT/CLAUDE.md"; then
        echo -e "${GREEN}  ✓ CLAUDE.md includes automation documentation${NC}"
    else
        echo -e "${YELLOW}  ⚠ CLAUDE.md doesn't mention post-merge automation${NC}"
    fi
else
    echo -e "${RED}  ✗ CLAUDE.md not found${NC}"
fi
echo ""

if [ -f "$REPO_ROOT/DOCUMENTATION_AUTO_UPDATE.md" ]; then
    echo -e "${GREEN}  ✓ DOCUMENTATION_AUTO_UPDATE.md exists${NC}"
else
    echo -e "${YELLOW}  ⚠ DOCUMENTATION_AUTO_UPDATE.md not found (optional)${NC}"
fi
echo ""

# Check 5: Library directory structure
echo -e "${CYAN}✓ Checking Library directory...${NC}"
if [ -d "$REPO_ROOT/Library" ]; then
    echo -e "${GREEN}  ✓ Library directory exists${NC}"

    # Count documentation files
    doc_count=$(find "$REPO_ROOT/Library" -name "*.md" -type f 2>/dev/null | wc -l)
    echo -e "${GREEN}  ✓ Found $doc_count documentation files${NC}"
else
    echo -e "${YELLOW}  ⚠ Library directory not yet created (will be created when docs are added)${NC}"
fi
echo ""

# Check 6: Test Python availability
echo -e "${CYAN}✓ Checking Python availability...${NC}"
if command -v python3 &> /dev/null; then
    python_version=$(python3 --version 2>&1)
    echo -e "${GREEN}  ✓ Python 3 available: $python_version${NC}"
else
    echo -e "${RED}  ✗ Python 3 not found (required for automation)${NC}"
fi
echo ""

# Check 7: Test Git availability
echo -e "${CYAN}✓ Checking Git availability...${NC}"
if command -v git &> /dev/null; then
    git_version=$(git --version 2>&1)
    echo -e "${GREEN}  ✓ Git available: $git_version${NC}"
else
    echo -e "${RED}  ✗ Git not found${NC}"
fi
echo ""

# Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Verification complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Run 'git pull origin main' to test the post-merge hook"
echo "  2. The hook will automatically detect changed files"
echo "  3. Follow the displayed commands to update documentation"
echo ""
echo "For more information:"
echo "  - See CLAUDE.md (Automated Documentation Updates section)"
echo "  - See DOCUMENTATION_AUTO_UPDATE.md (full guide)"
echo "  - Run './scripts/update-docs-from-pull.sh' to manually check"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

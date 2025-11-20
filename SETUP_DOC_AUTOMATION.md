# Setting Up Documentation Automation

This guide explains how to set up and verify the automated documentation update system for MaxText.

## Quick Start

The automation is already installed! No setup required. Just start using it:

```bash
# 1. Clone/pull the repository
git clone <repo>
cd maxtext-library

# 2. Verify the setup (optional)
./scripts/verify-doc-automation.sh

# 3. Pull changes and watch the automation in action
git pull origin main
```

## What Gets Installed

When you clone the repository, the following files are included:

```
.git/hooks/
├── post-merge                      # Main git hook (auto-runs after pull/merge)
└── update-docs-helper.py           # Detection and notification script

scripts/
├── update-docs-from-pull.sh        # Manual trigger script
└── verify-doc-automation.sh        # Verification script

Documentation/
├── CLAUDE.md                       # Updated with automation section
├── DOCUMENTATION_AUTO_UPDATE.md    # Full automation guide
└── SETUP_DOC_AUTOMATION.md         # This file
```

## Verification

To verify the automation is properly installed:

```bash
./scripts/verify-doc-automation.sh
```

This checks:
- ✅ Post-merge hook exists and is executable
- ✅ Helper script exists and is executable
- ✅ Manual trigger script exists and is executable
- ✅ Documentation files are present
- ✅ Python 3 is available
- ✅ Git is installed

## Manual Setup (If Needed)

If the automation was not installed, set it up manually:

### Step 1: Create Post-Merge Hook

```bash
# Create the post-merge hook
cat > .git/hooks/post-merge << 'EOF'
#!/bin/bash
set -e
HOOK_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$(cd "$HOOK_DIR/../.." && pwd)"
HELPER_SCRIPT="$REPO_ROOT/.git/hooks/update-docs-helper.py"
if [ ! -f "$HELPER_SCRIPT" ]; then
    exit 0
fi
python3 "$HELPER_SCRIPT" "$REPO_ROOT"
EOF

# Make it executable
chmod +x .git/hooks/post-merge
```

### Step 2: Create Helper Script

Copy the contents of `.git/hooks/update-docs-helper.py` from `DOCUMENTATION_AUTO_UPDATE.md` or the existing repository.

```bash
chmod +x .git/hooks/update-docs-helper.py
```

### Step 3: Create Manual Trigger Script

Copy the contents of `scripts/update-docs-from-pull.sh` from the repository.

```bash
chmod +x scripts/update-docs-from-pull.sh
```

### Step 4: Verify Installation

```bash
./scripts/verify-doc-automation.sh
```

## How It Works After Setup

### Automatic (Post-Merge Hook)

```bash
$ git pull origin main

# Hook automatically runs and displays:
======================================================================
📚 Documentation Update Needed
======================================================================

The following source files have been changed and have corresponding
documentation that may need updating:

  ✓ src/MaxText/layers/attention_op.py
    → Library/src/MaxText/layers/attention_op.py.md

======================================================================

To update documentation, use Claude Code:

  Generate comprehensive documentation for src/MaxText/layers/attention_op.py

======================================================================
```

### Manual Trigger

```bash
./scripts/update-docs-from-pull.sh
```

## File Permissions

After setup, verify correct permissions:

```bash
# Check permissions
ls -l .git/hooks/post-merge
ls -l .git/hooks/update-docs-helper.py
ls -l scripts/update-docs-from-pull.sh
ls -l scripts/verify-doc-automation.sh

# All should show 'x' (executable) flag: -rwxr-xr-x
```

If permissions are wrong, fix them:

```bash
chmod +x .git/hooks/post-merge
chmod +x .git/hooks/update-docs-helper.py
chmod +x scripts/update-docs-from-pull.sh
chmod +x scripts/verify-doc-automation.sh
```

## Configuration

The automation requires:
- **Python 3** - For running the detection helper
- **Git** - For detecting changed files
- **Library/ directory** - Created automatically when docs are added

### Optional: Disable Automation

To temporarily disable the post-merge hook:

```bash
# Disable
mv .git/hooks/post-merge .git/hooks/post-merge.disabled

# Re-enable
mv .git/hooks/post-merge.disabled .git/hooks/post-merge
```

## Troubleshooting

### Hook Not Running

```bash
# Check if executable
ls -l .git/hooks/post-merge

# Make executable if needed
chmod +x .git/hooks/post-merge
```

### Helper Script Not Found Error

```bash
# Verify helper exists
ls -l .git/hooks/update-docs-helper.py

# Check it's executable
chmod +x .git/hooks/update-docs-helper.py
```

### Python Not Found

```bash
# Check Python 3 is installed
python3 --version

# Install if missing (macOS with Homebrew)
brew install python3

# Install if missing (Ubuntu/Debian)
sudo apt-get install python3
```

### Git Issues

```bash
# Verify git is available
git --version

# If hooks aren't running, check git config
git config --local --list
```

## Testing the Setup

### Test 1: Manual Detection

```bash
# Manually run the helper script
python3 .git/hooks/update-docs-helper.py "$(pwd)"

# Should list any changed files needing documentation updates
```

### Test 2: Simulate a Pull

```bash
# Make a test commit to simulate changes
echo "test" >> test_file.py
git add test_file.py
git commit -m "test commit"

# Now merge it to trigger the hook
git checkout -b test-merge
git checkout main
git merge test-merge

# Hook should run (though won't detect doc updates for test_file.py)
```

### Test 3: Manual Trigger

```bash
./scripts/update-docs-from-pull.sh
```

## Documentation

For detailed documentation about the automation:

- **CLAUDE.md** - Overview and quick reference
- **DOCUMENTATION_AUTO_UPDATE.md** - Complete guide and troubleshooting

For the documentation generation system itself:

- **CLAUDE.md** - Main documentation generation guide

## Support

If you encounter issues:

1. Run verification script: `./scripts/verify-doc-automation.sh`
2. Check troubleshooting section above
3. Review detailed guides in `DOCUMENTATION_AUTO_UPDATE.md`
4. Ensure Python 3 and Git are properly installed

## Next Steps

1. Verify setup: `./scripts/verify-doc-automation.sh`
2. Pull changes: `git pull origin main`
3. Follow hook notifications to update documentation
4. Read `CLAUDE.md` for comprehensive documentation guide

---

**Happy documenting!**

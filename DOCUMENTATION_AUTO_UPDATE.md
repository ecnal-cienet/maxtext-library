# MaxText Documentation Auto-Update Automation

This guide explains the automatic documentation update system for MaxText. When you pull changes from the main branch, the system automatically detects which files have been modified and notifies you if corresponding documentation exists and needs updating.

## How It Works

### Automatic Detection (Post-Merge Hook)

After running `git pull` or `git merge`, a git hook automatically:

1. **Detects changed files** - Identifies which files were modified in the pull
2. **Filters for source code** - Only considers `.py` files in `src/MaxText/`
3. **Checks for documentation** - Looks for corresponding files in `Library/`
4. **Notifies the developer** - Displays a formatted list of documentation that may need updating
5. **Provides instructions** - Shows the exact Claude Code command to update docs

### Example Output

After `git pull`:

```
======================================================================
📚 Documentation Update Needed
======================================================================

The following source files have been changed and have corresponding
documentation that may need updating:

  ✓ src/MaxText/layers/attention_op.py
    → Library/src/MaxText/layers/attention_op.py.md

  ✓ src/MaxText/inference/kvcache.py
    → Library/src/MaxText/inference/kvcache.py.md

======================================================================

To update documentation, use Claude Code:

  Generate comprehensive documentation for the following modules:
  - src/MaxText/layers/attention_op.py
  - src/MaxText/inference/kvcache.py

======================================================================
```

## Installation

The automation is already set up! The following files have been created:

```
.git/hooks/post-merge                          # Main hook script
.git/hooks/update-docs-helper.py               # Detection logic
scripts/update-docs-from-pull.sh               # Manual trigger script
```

These are automatically executed by Git.

## Usage

### Automatic Usage (Default)

Just use Git normally:

```bash
# Pull changes from main branch
git pull origin main

# The hook automatically runs and notifies you of documentation updates needed
```

### Manual Trigger

If you want to check for documentation updates without pulling:

```bash
# View what documentation needs updating
./scripts/update-docs-from-pull.sh
```

### Updating Documentation

When the hook notifies you of changes:

1. **Copy the command** from the hook output
2. **Paste into Claude Code** to regenerate documentation

Example:
```
Generate comprehensive documentation for the following modules:
- src/MaxText/layers/attention_op.py
- src/MaxText/inference/kvcache.py
```

The documentation will be automatically updated in the Library directory.

## How the System Identifies Documentation Files

For each source file, the system looks for documentation at:

```
Source:          src/MaxText/layers/attention_op.py
Documentation:   Library/src/MaxText/layers/attention_op.py.md
```

The pattern is: `Library/[source_file].md`

Examples:
| Source File | Documentation File |
|------------|------------------|
| `src/MaxText/train.py` | `Library/src/MaxText/train.py.md` |
| `src/MaxText/layers/models.py` | `Library/src/MaxText/layers/models.py.md` |
| `src/MaxText/maxengine.py` | `Library/src/MaxText/maxengine.py.md` |
| `src/MaxText/inference/kvcache.py` | `Library/src/MaxText/inference/kvcache.py.md` |

## Workflow Example

### Scenario: Colleague updates attention_op.py

1. **You run**: `git pull origin main`
2. **Hook detects**: `src/MaxText/layers/attention_op.py` changed
3. **Hook checks**: Documentation exists at `Library/src/MaxText/layers/attention_op.py.md`
4. **Hook notifies**:
   ```
   📚 Documentation Update Needed
   ✓ src/MaxText/layers/attention_op.py
   → Library/src/MaxText/layers/attention_op.py.md
   ```
5. **You run Claude Code**:
   ```
   Generate comprehensive documentation for src/MaxText/layers/attention_op.py
   ```
6. **Documentation is updated** automatically in the Library directory

## Implementation Details

### Post-Merge Hook (`post-merge`)

- Executes after every successful merge (including `git pull`)
- Calls the Python helper script
- Non-blocking - never fails the merge
- Runs silently if no changes detected

### Helper Script (`update-docs-helper.py`)

Key functions:

- **`get_changed_files()`** - Uses git to detect all changed files
- **`get_source_files()`** - Filters to Python files in `src/MaxText/`
- **`should_update_docs()`** - Checks if documentation exists
- **Colored output** - User-friendly terminal formatting
- **Persistence** - Saves list to `.git/docs-to-update.txt` for scripting

### Temporary File

After each merge, a file is created:
```
.git/docs-to-update.txt
```

This contains a list of source files needing documentation updates, useful for:
- Automated workflows
- CI/CD integration
- Batch processing
- Scripting

## Disabling the Automation

If you need to temporarily disable the hook:

```bash
# Disable (rename the hook)
mv .git/hooks/post-merge .git/hooks/post-merge.disabled

# Re-enable
mv .git/hooks/post-merge.disabled .git/hooks/post-merge
```

## Customizing the Behavior

### Modifying Detection Logic

Edit `.git/hooks/update-docs-helper.py` to:
- Change which files are considered (currently `src/MaxText/` only)
- Modify output format
- Add additional filtering

### Ignoring Specific Files

Add to the helper script's filtering logic to exclude certain paths.

## Integration with CI/CD

The automation can be extended for CI/CD pipelines:

```bash
# In CI pipeline: Check if documentation needs updating
python3 .git/hooks/update-docs-helper.py "$PWD"

# Extract which files need updates
if [ -f .git/docs-to-update.txt ]; then
    echo "Documentation updates needed"
    cat .git/docs-to-update.txt
fi
```

## Troubleshooting

### Hook not running after pull

**Cause**: Hook file lost execute permissions

**Solution**:
```bash
chmod +x .git/hooks/post-merge
chmod +x .git/hooks/update-docs-helper.py
```

### No notification after pull

**Possible reasons**:
1. No Python files in `src/MaxText/` were changed
2. Changed files don't have corresponding documentation
3. Merge didn't complete successfully
4. Hook is disabled

**Debug**:
```bash
# Manually run the helper
python3 .git/hooks/update-docs-helper.py "$(pwd)"
```

### "Helper script not found" error

**Cause**: Script location changed or deleted

**Solution**: Reinstall using the setup instructions

## Best Practices

1. **Act on notifications** - Update documentation soon after pulling changes
2. **Keep docs in sync** - Documentation should reflect current code
3. **Commit docs changes** - Include documentation updates in your commits
4. **Review changes** - Use Claude Code to verify generated documentation quality

## Related Documentation

- See `CLAUDE.md` for comprehensive documentation generation guidelines
- Documentation is stored in `Library/` directory
- Each module gets a `.md` file with full coverage

## FAQ

**Q: What if multiple files changed?**
The hook lists all changed files and provides a batch command for Claude Code.

**Q: Does the hook fail if Python isn't installed?**
No - it gracefully exits and notifies you.

**Q: Can I commit without updating documentation?**
Yes - the hook is non-blocking. Documentation updates are optional but recommended.

**Q: How often does the hook run?**
Only after successful `git pull` or `git merge` operations.

**Q: What about other branches?**
The hook works with any branch merge, not just main.

---

## Summary

The documentation auto-update system:
- ✅ Automatically detects changed files after `git pull`
- ✅ Identifies corresponding documentation that may need updating
- ✅ Provides easy-to-use commands for Claude Code
- ✅ Non-blocking and zero configuration
- ✅ Saves update list for scripting/CI integration

Start using it today - no setup needed!

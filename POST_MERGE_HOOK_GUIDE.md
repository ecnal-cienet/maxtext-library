# Understanding the Post-Merge Hook

## When Does It Run?

The post-merge hook **only runs when git actually performs a merge**. Here are the scenarios:

### ✅ Hook WILL Run (Merge Operations)
- `git pull origin main` - When there are new commits to merge
- `git merge feature-branch` - When merging a branch
- `git rebase` - Some rebase operations
- Any operation that results in a merge commit

### ❌ Hook Will NOT Run (No Merge)
- `git pull origin main` - When branch is already up to date (fast-forward or no changes)
- `git fetch` - Fetching without merging
- `git status` - Just checking status
- `git log` - Just viewing history

## Current Status: Branch Already Up-to-Date

Your branch is currently up to date with `origin/main`:
```
Your branch is up to date with 'origin/main'.
```

When you ran `git pull`, git found no new commits to merge, so the post-merge hook did not execute.

## How to Test the Hook

### Option 1: Manual Test (Recommended)

Run the test script to see what the hook would do:

```bash
./scripts/test-doc-automation.sh
```

This runs the helper script directly and shows the same output as the hook would.

### Option 2: Create a Test Merge

If you want to see the hook actually run:

```bash
# Create a test branch
git checkout -b test-merge-hook
echo "test" > test_file.txt
git add test_file.txt
git commit -m "test commit"

# Go back to main
git checkout main

# Merge the branch (this WILL trigger the post-merge hook)
git merge test-merge-hook

# Clean up
git branch -d test-merge-hook
rm test_file.txt
```

When you run `git merge test-merge-hook`, the post-merge hook will automatically execute.

### Option 3: Wait for Real Merges

The hook will automatically run the next time:
- A teammate pushes changes that you need to merge
- You pull and there are commits to merge from `origin/main`
- You explicitly merge a branch

## How It Works When It Does Run

```
1. You run: git pull origin main
2. Git fetches and finds new commits to merge
3. Git performs the merge
4. Git automatically runs: .git/hooks/post-merge
5. Hook runs: update-docs-helper.py
6. Helper detects changed files
7. Helper checks for documentation
8. Helper displays notification (if docs exist)
```

## Example Output When Hook Runs

When the hook runs and finds documentation that needs updating, you'll see:

```
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

## Verification

The hook is correctly installed and will work. You can verify:

```bash
# Check hook exists and is executable
ls -l .git/hooks/post-merge
# Should show: -rwx--x--x (executable)

# Check helper script exists
ls -l .git/hooks/update-docs-helper.py
# Should show: -rwx--x--x (executable)

# Run verification script
./scripts/verify-doc-automation.sh
```

## Common Questions

**Q: Does my hook setup break anything?**
A: No. Post-merge hooks that fail silently don't prevent the merge. Your hook is non-blocking.

**Q: Is the hook installed correctly?**
A: Yes. Run `./scripts/verify-doc-automation.sh` to confirm all components are working.

**Q: Why didn't it run when I pulled?**
A: Your branch is already up to date. No merge happened, so the hook didn't trigger.

**Q: How can I test it without waiting for a real merge?**
A: Run `./scripts/test-doc-automation.sh` to simulate a merge detection.

**Q: Will it run for all merges or just main branch?**
A: It runs for all merges, regardless of branch. Any merge operation triggers the post-merge hook.

## Next Steps

1. The hook is correctly installed ✅
2. Test it when you next have a merge: `./scripts/test-doc-automation.sh`
3. Or manually test by creating a test branch and merging
4. It will automatically run next time someone pushes changes you need to merge

For more details, see:
- CLAUDE.md (Automated Documentation Updates section)
- DOCUMENTATION_AUTO_UPDATE.md (Complete guide)

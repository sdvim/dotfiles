# Create a pull request with atomic commits from current changes.

## Instructions

### Step 1: Create a new branch

Determine branch naming convention and create a new branch:

```bash
# Get recent branches by current user, fallback to all authors if none found
BRANCHES=$(git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads --count=10 --author="$(git config user.name)" 2>/dev/null | head -10)
[ -z "$BRANCHES" ] && BRANCHES=$(git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads --count=10 2>/dev/null | head -10)
echo "Recent branches for naming convention:"
echo "$BRANCHES"
```

Based on the branch naming patterns above, create a new branch with a name that:
- Follows the existing convention (e.g., `feature/xxx`, `fix/xxx`, `username/xxx`, `xxx-xxx-xxx`)
- Describes the changes you're about to commit

Use `git checkout -b <branch-name>` to create and switch to the new branch.

### Step 2: Create atomic commits

Follow the same process as /commit:

1. **Analyze changes**: Run `git status` and `git diff` to understand all changes
2. **Identify atomic units**: Group related changes that represent a single logical change
3. **Stage selectively**: Use `git add -p` for patch staging when needed
4. **Commit atomically**: Each commit should represent one logical change

Detect commit message convention:

```bash
CONVENTION=$(git log --oneline -5 2>/dev/null | awk '{print $2}' | grep -cE '^(Add|Remove|Delete|Fix|Update|Refactor|Clean|Simplify|Move|Rename|Improve|Create|Revert|Bump|Set|Use|Make|Replace|Enable|Disable|Support|Drop)$' | xargs -I{} sh -c '[ {} -ge 3 ] && echo simple || echo semantic')
echo "Detected commit convention: $CONVENTION"
```

### Step 3: Check for PR template

```bash
# Find PR template
TEMPLATE=$(find . -maxdepth 3 -type f \( -name "pull_request_template.md" -o -name "PULL_REQUEST_TEMPLATE.md" -o -path "./.github/PULL_REQUEST_TEMPLATE/*" \) 2>/dev/null | head -1)
[ -n "$TEMPLATE" ] && echo "Found PR template: $TEMPLATE" && cat "$TEMPLATE" || echo "No PR template found"
```

### Step 4: Push and create draft PR

1. Push the branch: `git push -u origin HEAD`
2. Create the PR as a draft using `gh pr create --draft`
   - If a PR template was found, use its structure for the PR body
   - Fill in the template sections based on the commits made
   - If no template, write a clear summary of changes

```bash
# Example PR creation (adjust title and body based on changes)
gh pr create --draft --title "PR Title" --body "PR body following template or summary"
```

### Step 5: Monitor CI and fix failures

After pushing the PR:

1. Run `gh pr checks --watch` to monitor CI status
2. If any checks fail, run `gh pr checks` to see which ones
3. Fetch logs with `gh run view <run-id> --log-failed`
4. Investigate and fix the issues
5. Push fixes and repeat until all checks pass

## Output

When complete, display:
- The new branch name
- List of commits made (`git log --oneline main..HEAD` or similar)
- Link to the created draft PR
- CI status (all checks passing)

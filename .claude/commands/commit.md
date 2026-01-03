# Create sensible, atomic commits from staged and unstaged changes.

## Instructions

1. **Analyze changes**: Run `git status` and `git diff` to understand all changes
2. **Identify atomic units**: Group related changes that represent a single logical change
3. **Stage selectively**: Use `git add -i` for interactive staging when a file contains multiple unrelated changes (chunk staging encouraged for complex files)
4. **Commit atomically**: Each commit should represent one logical change

## Commit Message Convention

Detect the repo's convention by running:

```bash
CONVENTION=$(git log --oneline -5 2>/dev/null | awk '{print $2}' | grep -cE '^(Add|Remove|Delete|Fix|Update|Refactor|Clean|Simplify|Move|Rename|Improve|Create|Revert|Bump|Set|Use|Make|Replace|Enable|Disable|Support|Drop)$' | xargs -I{} sh -c '[ {} -ge 3 ] && echo simple || echo semantic')
echo "Detected convention: $CONVENTION"
```

**If `simple`** (3+ of last 5 commits use imperative verbs):
- Use imperative mood: "Add feature" not "Added feature"
- Keep the title brief and descriptive
- Examples: `Add user authentication`, `Remove deprecated API`, `Fix null pointer in parser`

**If `semantic`** (default when no clear pattern):
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation only
- `style:` Formatting, no code change
- `refactor:` Code restructuring, no behavior change
- `test:` Adding/updating tests
- `chore:` Maintenance tasks

## Process

1. Review all changes with `git status` and `git diff`
2. Determine commit message convention from recent history
3. For each atomic unit of change:
   - Stage the relevant files/chunks
   - Write a clear commit message following the detected convention
   - Commit
4. Verify with `git log --oneline -5` when complete

# Commit Command

Create sensible, atomic commits from staged and unstaged changes.

## Instructions

1. **Analyze changes**: Run `git status` and `git diff` to understand all changes
2. **Identify atomic units**: Group related changes that represent a single logical change
3. **Stage selectively**: Use `git add -i` for interactive staging when a file contains multiple unrelated changes (chunk staging encouraged for complex files)
4. **Commit atomically**: Each commit should represent one logical change

## Commit Message Convention

First, check the repository's existing convention by examining recent commits:

```bash
git log --oneline -10 | awk '{print $2}'
```

**If the pattern shows simple verbs** (Add, Remove, Update, Fix, Refactor, Simplify, etc.):
- Use imperative mood: "Add feature" not "Added feature"
- Keep the title brief and descriptive
- Examples: `Add user authentication`, `Remove deprecated API`, `Fix null pointer in parser`

**If the pattern shows semantic prefixes** (feat, fix, chore, docs, etc.) or no clear pattern exists, default to [Semantic Commit Messages](https://gist.github.com/joshbuchea/6f47e86d2510bce28f8e7f42ae84c716):
- `feat(scope)`: New feature
- `fix(scope)`: Bug fix
- `docs(scope)`: Documentation only
- `style(scope)`: Formatting, no code change
- `refactor(scope)`: Code restructuring, no behavior change
- `test(scope)`: Adding/updating tests
- `chore(scope)`: Maintenance tasks

## Process

1. Review all changes with `git status` and `git diff`
2. Determine commit message convention from recent history
3. For each atomic unit of change:
   - Stage the relevant files/chunks
   - Write a clear commit message following the detected convention
   - Commit
4. Verify with `git log --oneline -5` when complete

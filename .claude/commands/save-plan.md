# Save a discussion plan as a markdown file for future implementation.

## Instructions

When the user has discussed a potential feature, configuration, or change but doesn't want to implement it yet, save the plan for future reference.

### Step 1: Summarize the discussion

Review the conversation and identify:
- The goal or problem being solved
- The proposed solution or approach
- Any implementation steps discussed
- Trade-offs or considerations mentioned

### Step 2: Choose a filename

Create a descriptive kebab-case filename based on the topic, e.g.:
- `per-directory-max-auth.md`
- `neovim-lsp-setup.md`
- `zsh-prompt-customization.md`

### Step 3: Create the plan file

Save to `.claude/plans/<filename>.md` with this structure:

```markdown
# Title

## Goal

Brief description of what this accomplishes.

## Background

Context and reasoning behind the approach.

## Implementation Plan

### 1. First step

Details and code snippets.

### 2. Second step

Details and code snippets.

## Considerations

- Trade-offs
- Things to watch out for
- Alternative approaches considered

## Status

Not yet implemented - saved for future reference.
```

### Step 4: Confirm with the user

After creating the file, show the path and offer to commit it.

## Notes

- Replace any employer names, private project names, or sensitive info with generic terms (e.g., "work" instead of company name)
- Include code snippets and commands that were discussed
- Keep the plan actionable so a future session can implement it

# Stash a discussion plan for later retrieval.

## Instructions

When the user has discussed a potential feature or change but wants to switch contexts without losing the plan, create and stash it for later.

### Step 1: Summarize the discussion

Review the conversation and identify:
- The goal or problem being solved
- The proposed solution or approach
- Any implementation steps discussed
- Trade-offs or considerations mentioned

### Step 2: Choose a filename and title

Create a descriptive kebab-case filename and short title based on the topic:
- Filename: `add-dark-mode-toggle.md`
- Title: `Add dark mode toggle`

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

Stashed for future implementation.
```

### Step 4: Stash the plan

```bash
# Stage only the plan file
git add .claude/plans/<filename>.md

# Stash with descriptive message
git stash push -m "Claude Plan: <short title>" -- .claude/plans/<filename>.md
```

### Step 5: Confirm with the user

Show the stash entry and how to retrieve it later:

```bash
# View stashes
git stash list

# Apply the plan later
git stash pop  # or git stash apply stash@{n}
```

## Notes

- Replace any employer names, private project names, or sensitive info with generic terms
- Include code snippets and commands that were discussed
- Keep the plan actionable so a future session can implement it
- The stash message format "Claude Plan: <title>" makes it easy to identify Claude-generated plans

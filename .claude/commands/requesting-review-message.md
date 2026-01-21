# Generate a "requesting review" message for the current PR.

## Instructions

1. Mark the PR as ready for review:

```bash
gh pr ready
```

2. Get the current PR details for this branch:

```bash
gh pr view --json number,title,url,additions,deletions
```

3. Clean up the title by removing any `ENG-####: ` prefix (e.g., `ENG-1234: Fix bug` becomes `Fix bug`)

4. Format the following message:

```
*requesting review*: <title> [#<number>](<url>) `+<additions> -<deletions>`
```

## Output

1. Copy the formatted message to the clipboard using `pbcopy`
2. Confirm to the user that the message was copied

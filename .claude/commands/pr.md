---
description: Create a PR from current changes with Linear issue integration
---

You are executing the /pr command. Follow these steps EXACTLY and IN ORDER. Stop immediately with a clear error message if any step fails.

## STEP 1: Validate Prerequisites

1. Run `git status` to check for uncommitted changes
2. If there are NO changes (clean working tree), STOP and output: "Error: No uncommitted changes found. Make changes first before running /pr."
3. If not in a git repository, STOP and output: "Error: Not in a git repository."
4. Check current branch with `git branch --show-current`
5. If not on main/master, ask user: "You're on branch '{current_branch}'. Continue creating PR from here? (y/n)"

## STEP 2: Process Linear Issue (if $ARGUMENTS provided)

**If $ARGUMENTS is empty**: Skip to STEP 3 with `issue_identifier = "no-task"` and `issue_description = null`

**If $ARGUMENTS is provided** (e.g., "ENG-123" or "123"):
1. Format the issue identifier: If $ARGUMENTS is just a number, prepend "ENG-". Otherwise use as-is.
2. Use Linear MCP to search for and retrieve the issue with the formatted identifier
3. If issue NOT found, STOP and output: "Error: Linear issue '{identifier}' not found. Check the issue number and try again."
4. If issue found:
   - Extract the issue title
   - Convert title to kebab-case
   - Extract the 3-4 most meaningful keywords (skip articles like "the", "a", "an", and common words like "to", "and", "or")
   - Store as `issue_description` (e.g., "implement-user-authentication")
   - Store formatted identifier as `issue_identifier` (e.g., "eng-123")
   - Store the issue URL for later use

## STEP 3: Auto-detect Branch Type

Analyze the git changes to determine branch type:

1. Run `git status --short` and `git diff --stat`
2. Analyze the changes:
   - If mainly NEW files or significant new functionality: `branch_type = "feature"`
   - If modifying existing files with "fix", "bug", "error", "issue" in context: `branch_type = "fix"`
   - If removing files, refactoring, or reorganizing: `branch_type = "cleanup"`
   - Default to `feature` if ambiguous
3. Output the detected type: "Detected branch type: {branch_type}"

## STEP 4: Generate and Confirm Branch Name

1. Generate branch name in format: `{branch_type}/{issue_identifier}-{description}`
   - If $ARGUMENTS was provided: Use `issue_description` from Linear
   - If no $ARGUMENTS: Ask user for brief description (3-4 words), convert to kebab-case
2. Output: "Creating branch: {branch_name}"
3. Ask user: "Proceed with this branch name? (y/n)"
4. If no, ask for custom branch name
5. Run `git checkout -b {branch_name}` to create and switch to the branch

## STEP 5: Organize and Create Commits

Follow this EXACT order for commits:

**Phase 1: New Files (Adds)**
1. Run `git status --short` and identify all untracked files (lines starting with "??")
2. Group related new files logically if possible
3. For each group:
   - Stage files with `git add {files}`
   - Create commit with message format: "Add {brief description of what was added}"
   - Follow imperative mood (Add, not Added or Adding)

**Phase 2: Modified Files (Updates)**
1. Identify all modified files (lines starting with "M" or "MM")
2. Group related modifications logically if possible
3. For each group:
   - Stage files with `git add {files}`
   - Create commit with message format: "Update {brief description}" or "Fix {what was fixed}" based on context
   - Follow imperative mood

**Phase 3: Deleted Files (Deletes)**
1. Identify all deleted files (lines starting with "D")
2. Group related deletions logically if possible
3. For each group:
   - Stage files with `git add {files}`
   - Create commit with message format: "Remove {brief description of what was removed}"
   - Follow imperative mood

**Commit Message Standards:**
- Use imperative mood: "Add", "Update", "Fix", "Remove", "Clean up", "Configure", "Consolidate", "Move"
- Be specific and concise
- Reference what changed, not how or why (that goes in commit body if needed)
- Each commit should append the Claude Code signature:

```
{commit message}

Generated with Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>
```

## STEP 6: Create Draft Pull Request

1. Check for PR template in current repo:
   - Look for `.github/PULL_REQUEST_TEMPLATE.md` or `.github/pull_request_template.md`
   - If found, read the template

2. Generate PR body:

   **If template exists:**
   - Use template as base
   - Fill in any obvious placeholders
   - Add Linear issue link at the top if $ARGUMENTS was provided

   **If no template exists, use this format:**
   ```markdown
   ## Summary
   {If Linear issue: use issue title. Otherwise: brief description based on branch name}

   ## Changes
   {List all commit messages as bullet points}

   ## Linear Issue
   {If $ARGUMENTS was provided: Link to Linear issue. Otherwise: "No associated issue"}

   ## Testing
   - [ ] Changes tested locally
   - [ ] No new errors or warnings

   Generated with Claude Code
   ```

3. Generate PR title:
   - If Linear issue: Use issue title
   - Otherwise: Use branch description converted to title case

4. Create draft PR:
   ```bash
   gh pr create --draft --title "{pr_title}" --body "{pr_body}"
   ```

5. If `gh pr create` fails, output the error and provide the PR body to user so they can create it manually

## STEP 7: Summary and Next Steps

Output a summary:
```
✓ Created branch: {branch_name}
✓ Created {N} commits
✓ Draft PR created: {pr_url}

Next steps:
1. Review the commits with: git log
2. Review the PR: gh pr view --web
3. When ready, push with: git push -u origin {branch_name}
4. Mark PR as ready for review when ready
```

## Error Handling

At ANY step, if you encounter an error:
1. Output the error clearly: "Error at STEP {N}: {error message}"
2. Provide guidance on how to resolve it
3. Do NOT continue to next steps
4. Do NOT leave the repository in a broken state (e.g., if branch creation fails, don't create commits)

---

Remember: Be explicit, validate at each step, and prioritize predictability over automation.

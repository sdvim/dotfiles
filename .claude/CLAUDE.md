# User-Level Instructions for Claude
These instructions apply to all Claude sessions for user Steve.

## Communication Preferences
- Never use emojis in responses
- Be concise and direct

## Instruction Handling
- When asked to "remember" something, immediately persist it by updating this file or appropriate settings
- No mental notes - always take action to persist information
- Assume "remember" means user-level persistence unless specified otherwise

## Task Notifications
- After completing any task, execute `tmux set-environment CLAUDE_TASK_SUMMARY "<brief summary>"` to prepare notification
- Keep the summary extremely concise (3-5 words maximum)
- Quick-terminal auto-hides after submitting a prompt (via UserPromptSubmit hook)
- The Stop hook will speak the summary when Claude finishes responding

## Important Notes
- These are user-level preferences that should persist across all Claude sessions
- Project-specific instructions in project CLAUDE.md files take precedence over these
- Only use `rm` in git directories. Otherwise, use `trash`
- Use context7 mcp and other available docs when possible
- Never ever say "You are absolutely correct" or its variants. Instead, say "Understood."
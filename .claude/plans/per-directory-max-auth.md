# Per-Directory Claude Max Authentication

## Goal

Use different Claude Max accounts based on directory patterns:
- `~/Git/work-*` directories should use work Max account
- All other directories should use personal Max account

## Background

Claude Code stores Max auth sessions globally. There's no built-in way to switch accounts based on directory. However, the `CLAUDE_CONFIG_DIR` environment variable can point to different config directories, each with their own auth session.

## Implementation Plan

### 1. Create separate config directory for work

```bash
mkdir -p ~/.claude-work
```

### 2. Log in to work account

```bash
CLAUDE_CONFIG_DIR="$HOME/.claude-work" claude
# Complete OAuth login with work Max account
```

### 3. Add shell function to .zshenv or .zshrc

```bash
claude() {
  if [[ "$PWD" == "$HOME/Git/work-"* ]]; then
    CLAUDE_CONFIG_DIR="$HOME/.claude-work" command claude "$@"
  else
    command claude "$@"
  fi
}
```

This automatically selects the correct account based on the current directory.

## Considerations

- Need to maintain two separate config directories
- Settings in `.claude-work/settings.json` would be separate from main config
- May want to symlink shared settings between them
- Will need to re-authenticate each config dir separately when sessions expire

## Status

Not yet implemented - saved for future reference.

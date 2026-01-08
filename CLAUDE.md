# Dotfiles Repository

## Symlinks

Use `stow` to manage symlinks where possible.

```bash
# From the dotfiles directory, stow a package:
stow <package>
```

Note: `~/.claude/commands/` currently uses manual symlinks with relative paths (e.g., `../../dotfiles/.claude/commands/file.md`). Match that pattern when adding new commands:

```bash
ln -s ../../dotfiles/.claude/commands/<file>.md ~/.claude/commands/<file>.md
```

# Dotfiles Repository

## Symlinks

Use `stow` to manage symlinks. Never create manual symlinks.

```bash
# From the dotfiles directory, stow a package:
stow <package>
```

## Zsh Configuration

Environment variables go in `.zshenv`, not `.zshrc`. This ensures variables are available in all shell contexts (scripts, non-interactive shells, SSH sessions).

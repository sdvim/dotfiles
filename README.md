# Dotfiles

This repository manages configuration files using GNU Stow for symlink management.

## Setup

1. Clone this repository to `~/dotfiles`
2. Install dependencies via Homebrew (see `.config/homebrew/Brewfile`)
3. Apply configurations: `stow .`

## Structure

- **Root level**: Direct home directory dotfiles (`.zshrc`, `.gitconfig`, etc.)
- **`.config/`**: XDG Base Directory compliant configurations
- **`.stow-local-ignore`**: Files to exclude from stow management

## Key Features

### Shell (zsh)
- History management with sharing and deduplication
- Autosuggestions and syntax highlighting via Homebrew packages
- Aliases for modern CLI tools (eza, fd, rg, bat)
- Auto-directory change to dotfiles on login
- Auto-apply dotfiles with change detection on login

### Tmux
- 1-based window/pane numbering with auto-renumbering
- Mouse support with proper scrolling behavior
- Custom status line styling
- UTF-8 and 256-color support

### Claude AI Integration
- Global MCP server configuration at `.config/claude/mcp.json`
- Context7 MCP server available across all directories
- Claude alias automatically loads MCP configuration

### Git
- Shared configuration and ignore patterns
- User-specific settings

### Terminal Tools
- Ghostty terminal emulator configuration
- Starship prompt with conditional Unicode support for Terminus
- Zoxide for smart directory jumping

## Usage

```bash
# Apply all configurations
stow .

# Apply specific configuration
stow --target=$HOME .config/git

# Remove configurations
stow -D .
```

The system automatically applies dotfiles on shell startup and reports any changes.
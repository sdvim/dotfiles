# Dotfiles

## Keyboard Automation

- Karabiner handles low-level keyboard remaps: Caps Lock as Control, external keyboard Command/Option swapping, app-switcher suppression, and small app-scoped key remaps.
- Hammerspoon handles higher-level app automation that benefits from resident state, currently fast Ghostty pane selection with `cmd+1` through `cmd+9`. `setup-macos` points Hammerspoon at `~/.config/hammerspoon/init.lua` with `MJConfigFile`.

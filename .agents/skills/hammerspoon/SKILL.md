---
name: hammerspoon
description: Edit and validate this dotfiles repo's Hammerspoon automation configuration. Use when Codex is asked to add, remove, explain, or troubleshoot Hammerspoon hotkeys, app watchers, timers, AppleScript bridges, launch-at-login behavior, MJConfigFile setup, or entries in dot_config/hammerspoon/init.lua.
---

# Hammerspoon

## Scope

Edit `dot_config/hammerspoon/init.lua` for Hammerspoon configuration changes.

The repo uses Hammerspoon's `MJConfigFile` default, configured by `setup-macos`, to load `~/.config/hammerspoon/init.lua` directly.

Do not change Karabiner, Ghostty, AeroSpace, zsh, or broader dotfiles config for Hammerspoon work unless the user explicitly asks for it.

## Docs

Use official Hammerspoon docs when Lua APIs, hotkey behavior, app watchers, timers, IPC, AppleScript bridges, or launch-at-login behavior are uncertain:

- `https://www.hammerspoon.org/docs/hs.hotkey.html`
- `https://www.hammerspoon.org/docs/hs.application.html`
- `https://www.hammerspoon.org/docs/hs.application.watcher.html`
- `https://www.hammerspoon.org/docs/hs.timer.html`
- `https://www.hammerspoon.org/docs/hs.eventtap.html`
- `https://www.hammerspoon.org/docs/hs.osascript.html`
- `https://www.hammerspoon.org/docs/hs.ipc.html`
- `https://www.hammerspoon.org/docs/hs.html`

Use local introspection commands before changing app-specific automation:

- `hs -A -c 'return hs.application.frontmostApplication():bundleID()'`
- `hs -A -c 'return hs.inspect(hs.hotkey.getHotkeys())'`
- `osascript -e 'id of app "<Application Name>"'`
- `defaults read org.hammerspoon.Hammerspoon MJConfigFile`

## Workflow

1. Read `dot_config/hammerspoon/init.lua` and preserve its existing Lua style.
2. Make the smallest change that satisfies the request. Keep app-aware resident automation in Hammerspoon; keep low-level keyboard and device remaps in Karabiner unless the user asks to move them.
3. For app-specific hotkeys, enable hotkeys only while the target app is frontmost, or make pass-through behavior explicit.
4. When adding hotkeys that call AppleScript or shell commands, prefer resident Hammerspoon APIs over launching a new process per keypress when latency matters.
5. Validate Lua syntax with:

```bash
luac -p dot_config/hammerspoon/init.lua
```

6. Apply and reload:

```bash
chezmoi apply --force --source "$PWD" -- ~/.config/hammerspoon/init.lua && chezmoi diff --source "$PWD" -- ~/.config/hammerspoon/init.lua && defaults write org.hammerspoon.Hammerspoon MJConfigFile -string "$HOME/.config/hammerspoon/init.lua" && hs -A -c 'hs.reload()'
```

If reload invalidates the CLI connection, wait and poll:

```bash
sleep 2
hs -A -c 'return true'
```

If `hs` cannot connect, make sure Hammerspoon is running and `hs.ipc.cliInstall()` is loaded before relying on CLI validation.

7. Verify relevant globals or state for the changed automation. For current Ghostty pane hotkeys:

```bash
hs -A -c 'return #ghosttyPaneHotkeys, ghosttyPaneWatcher ~= nil, ghosttyPaneSyncTimer ~= nil, hs.autoLaunch()'
```

Report whether syntax validation passed, whether the target diff is clean, whether reload succeeded, any permission issue, and any manual physical-key checks still needed.

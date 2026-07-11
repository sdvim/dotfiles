---
name: ghostty
description: Edit and validate this dotfiles repo's Ghostty terminal configuration. Use when Codex is asked to create, add, remove, explain, or troubleshoot Ghostty config, themes, fonts, keybindings, window behavior, shell integration, or entries in dot_config/ghostty/config.ghostty.
---

# Ghostty

## Scope

Edit only `dot_config/ghostty/config.ghostty` for Ghostty configuration changes.

Do not make broader dotfiles changes for Ghostty unless the user explicitly asks for them.

## Docs

Use the official Ghostty docs when config syntax, available options, or keybinding behavior is uncertain:

- `https://ghostty.org/docs/config`
- `https://ghostty.org/docs/config/reference`
- `https://ghostty.org/docs/config/keybind`

Use local Ghostty references when available:

- `/Applications/Ghostty.app/Contents/Resources/ghostty/doc/ghostty.5.md`
- `/Applications/Ghostty.app/Contents/Resources/ghostty/doc/ghostty.1.md`
- `ghostty +show-config --default --docs`

Use local introspection commands before changing unfamiliar values:

- `ghostty +list-fonts`
- `ghostty +list-themes`
- `ghostty +list-actions`
- `ghostty +list-keybinds`

## Workflow

1. Read `dot_config/ghostty/config.ghostty` if it exists and preserve Ghostty's `key = value` style.
2. Make the smallest change that satisfies the request.
3. Validate the source config with:

```bash
ghostty +validate-config --config-file=dot_config/ghostty/config.ghostty
```

4. Apply and validate the target with:

```bash
chezmoi apply --source "$PWD" -- ~/.config/ghostty && chezmoi diff --source "$PWD" -- ~/.config/ghostty/config.ghostty
```

5. After validation passes, apply succeeds, and the target diff is clean, reload Ghostty config if Ghostty is running. On macOS, trigger the default `reload_config` keybinding:

```bash
osascript -e 'tell application "Ghostty" to activate' -e 'tell application "System Events" to keystroke "," using {command down, shift down}'
```

If the reload command fails, report the failure and do not claim the config was reloaded.

Report whether validation passed, whether the target diff is clean, whether reload was triggered, and call out any remaining config error or warning.

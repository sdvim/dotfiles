---
name: karabiner
description: Edit and validate this dotfiles repo's Karabiner-Elements keyboard remapping configuration. Use when Codex is asked to add, remove, explain, or troubleshoot Karabiner complex modifications, device-specific modifier remaps, app-scoped key rules, cmd-tab suppression, or entries in dot_config/karabiner/karabiner.json.
---

# Karabiner

## Scope

Edit only `dot_config/karabiner/karabiner.json` for Karabiner configuration changes.

Do not change Hammerspoon, Ghostty, AeroSpace, zsh, or broader dotfiles config for Karabiner work unless the user explicitly asks for it.

## Docs

Use official Karabiner-Elements docs when config syntax, conditions, device matching, modifiers, or `to` events are uncertain:

- `https://karabiner-elements.pqrs.org/docs/json/root-data-structure/`
- `https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/`
- `https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/conditions/device/`
- `https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/conditions/frontmost-application/`
- `https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/to/`
- `https://karabiner-elements.pqrs.org/docs/manual/misc/command-line-interface/`

Use local introspection commands before changing device-specific or app-specific rules:

- `karabiner_cli --show-current-profile-name`
- `karabiner_cli --list-connected-devices`
- `osascript -e 'id of app "<Application Name>"'`

## Workflow

1. Read `dot_config/karabiner/karabiner.json` and preserve valid JSON.
2. Make the smallest change that satisfies the request. Keep low-level keyboard and device policy in Karabiner; keep resident app automation in Hammerspoon unless the user asks to move it.
3. For device-specific rules, inspect `karabiner_cli --list-connected-devices` and avoid hard-coding a single external keyboard unless the user requested that exact device.
4. For app-scoped rules, verify the bundle id with `osascript -e 'id of app "<Application Name>"'` when the app is installed.
5. Validate the source config with:

```bash
jq empty dot_config/karabiner/karabiner.json
karabiner_cli --lint-complex-modifications 'dot_config/karabiner/karabiner.json'
```

6. Apply and validate the target with:

```bash
chezmoi apply --force --source "$PWD" -- ~/.config/karabiner/karabiner.json && chezmoi diff --source "$PWD" -- ~/.config/karabiner/karabiner.json && karabiner_cli --select-profile "$(karabiner_cli --show-current-profile-name)"
```

Report whether validation passed, whether the target diff is clean, which profile was selected, and any manual physical-key checks still needed.
